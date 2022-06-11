# Bare Metal Program

### Prepare
```
sudo -i
git clone https://github.com/hellof20/bare-metal.git
cd bare-metal
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
```


### Run Bare Metal server
```
nohup python3 baremetal.py > baremetal-server.log 2>&1 &
curl 127.0.0.1/health
```


### How to Use
- Open Web browser, input <u>http://your_server_ip</u>, Enter
- input <b>Project_ID</b> and <b>Bucket_Name</b>



### Current Deployment UI
![image](https://user-images.githubusercontent.com/8756642/173190814-6c332b9d-ffad-4e0c-a892-637b8fd9426f.png)
