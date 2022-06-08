#!/bin/bash
# https://cloud.google.com/sdk/gcloud/reference/functions/deploy
source bin/env.sh

# exit if any subcommand has error
set -euxo pipefail

# Enable APIs used in the solution
gcloud services enable 'firestore.googleapis.com'
gcloud services enable 'pubsub.googleapis.com'
gcloud services enable 'cloudfunctions.googleapis.com'
gcloud services enable 'appengine.googleapis.com'
gcloud services enable 'cloudscheduler.googleapis.com'
gcloud services enable 'cloudbuild.googleapis.com'
gcloud services enable 'cloudtasks.googleapis.com'
gcloud app create --region=$GCP_REGION || echo "App already created, skip"
gcloud alpha firestore databases create --region=$GCP_REGION

# Create GCS bucket
gsutil mb gs://$BUCKET_NAME/ || echo "bucket already exists, skip creation"

# Set up pubsub for event notitication
gcloud pubsub topics create $TOPIC_EXTERNAL || echo "topic already exists"
gcloud logging sinks create bq_complete_sink pubsub.googleapis.com/projects/$PROJECT_ID/topics/$TOPIC_EXTERNAL \
     --log-filter='resource.type="bigquery_resource" AND protoPayload.methodName="jobservice.jobcompleted"' || echo "sink already exists, skip"
sink_service_account=$(gcloud logging sinks describe bq_complete_sink |grep writerIdentity| sed 's/writerIdentity: //')
echo "bq sink service account: $sink_service_account"
gcloud pubsub topics add-iam-policy-binding $TOPIC_EXTERNAL \
     --member $sink_service_account --role roles/pubsub.publisher

gsutil cp example/google-ads.yaml gs://$BUCKET_NAME/config/google-ads.yaml
gsutil cp example/data.csv gs://$BUCKET_NAME/input/input-example.txt

$PIP install "google-auth>=1.24.0" "google-cloud-firestore>=1.6.2"

#sleep 120
echo 'sleep 120 to wait service enabled'
sleep 120

BUCKET_NAME=$BUCKET_NAME GOOGLE_CLOUD_PROJECT=$PROJECT_ID $PYTHON src/config.py

# Deploy cloud functions
gcloud iam service-accounts create forfunction --description="forfunction" --display-name="forfunction"
SERVICE_ACCOUNT=forfunction@$PROJECT_ID.iam.gserviceaccount.com
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$SERVICE_ACCOUNT" --role="roles/editor"
gcloud functions deploy start --project $PROJECT_ID --quiet --timeout=540 --runtime python37 --trigger-http --source $SRC_DIR --service-account=$SERVICE_ACCOUNT
gcloud functions deploy send_single_event --project $PROJECT_ID --quiet --timeout=540 --runtime python37 --trigger-http --source $SRC_DIR --service-account=$SERVICE_ACCOUNT
gcloud functions deploy pingback_worker --project $PROJECT_ID --quiet --timeout=540 --runtime python37  --trigger-http --source $SRC_DIR --service-account=$SERVICE_ACCOUNT
gcloud functions deploy scheduler --quiet --project $PROJECT_ID --timeout=540 --runtime python37 --trigger-topic $TOPIC_SCHEDULE --source $SRC_DIR --service-account=$SERVICE_ACCOUNT
gcloud functions deploy external_event_listener --project $PROJECT_ID --quiet --timeout=540 --runtime python37 --trigger-topic $TOPIC_EXTERNAL --source $SRC_DIR --service-account=$SERVICE_ACCOUNT

INPUT_PATH="gs://$BUCKET_NAME/input"
echo "Deployment success, please upload input files to $INPUT_PATH every day."
