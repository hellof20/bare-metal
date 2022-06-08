# -*- coding:utf-8 -*-
import os
from flask import Flask
from flask import request,render_template
from flask import jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return 'success'

@app.route('/')
def index():
    return render_template('baremetal.html')

@app.route('/install', methods=['POST'])
def process_register():
    PROJECT_ID = request.form.get("project_id")
    BUCKET_NAME = request.form.get("bucket_name")
    print(PROJECT_ID)
    print(BUCKET_NAME)
    os.system("mkdir -p customer_" + PROJECT_ID)
    os.system("cd ads-bare-metal && PROJECT_ID=%s BUCKET_NAME=%s nohup bash bin/deploy.sh > ../customer_%s/install.log 2>&1 &"%(PROJECT_ID, BUCKET_NAME, PROJECT_ID))
    return "installing"

if __name__ == '__main__':
      app.run(host='0.0.0.0', port=80)
