#!/bin/bash
apt-get update
apt-get install -y python3-pip
pip3 install flask

cat << 'PYTHON' > /home/linuxadmin/web_frontend.py
import urllib.request
from flask import Flask

app = Flask(__name__)

@app.route('/')
def index():
    try:
        
        req = urllib.request.urlopen('http://${internal_lb_ip}:8080/')
        api_response = req.read().decode('utf-8')
        return f"<h1>Web Tier Online!</h1><h3>App Tier Response:</h3><pre>{api_response}</pre>"
    except Exception as e:
        return f"<h1>Web Tier Online!</h1><p>Error connecting to App Tier: {e}</p>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
PYTHON

nohup sudo python3 /home/linuxadmin/web_frontend.py > /home/linuxadmin/web.log 2>&1 &