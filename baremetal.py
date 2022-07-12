# -*- coding:utf-8 -*-
import os
from flask import Flask
from flask import request,render_template
from flask import jsonify
from python_terraform import *

app = Flask(__name__)

bm = Terraform(working_dir='tf-tutorial')

@app.route('/health')
def health():
    return 'success'

@app.route('/')
def index():
    return render_template('baremetal.html')

@app.route('/apply', methods=['POST'])
def apply():
    PROJECT_ID = request.form.get("project_id")
    BUCKET_NAME = request.form.get("bucket_name")
    GCP_PROJECT = request.form.get("gcp_project")
    if GCP_PROJECT == "BareMetal":
        bm.init()
        return_code, stdout, stderr = bm.apply(skip_plan=True, var={'project':PROJECT_ID})
        if return_code == 0:
            print(stdout)
            return 'Deploy success'
        else:
            print(stdout)
            print(stderr)
            return 'Deploy failed'        
    else:
        return 'not supported'


@app.route('/destroy', methods=['POST'])
def destroy():
    PROJECT_ID = request.form.get("project_id")
    BUCKET_NAME = request.form.get("bucket_name")
    GCP_PROJECT = request.form.get("gcp_project")
    if GCP_PROJECT == "BareMetal":
        return_code, stdout, stderr = bm.destroy(force=IsNotFlagged, auto_approve=True, var={'project':PROJECT_ID})
        if return_code == 0:
            print(stdout)
            return 'Destroy success'
        else:
            print(stdout)        
            print(stderr)
            return 'Destroy failed'
    else:
        return 'not supported'   

if __name__ == '__main__':
      app.run(host='0.0.0.0', port=80)


    #os.system("mkdir -p customer_" + PROJECT_ID)
    #os.system("cd ads-bare-metal && PROJECT_ID=%s BUCKET_NAME=%s nohup bash bin/deploy.sh > ../customer_%s/install.log 2>&1 &"%(PROJECT_ID, BUCKET_NAME, PROJECT_ID))
    #os.system("cd tf-tutorial && terraform apply -auto-approve")