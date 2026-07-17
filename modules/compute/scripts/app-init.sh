#!/bin/bash
apt-get update
apt-get install -y python3-pip
pip3 install flask psycopg2-binary azure-storage-blob --break-system-packages

cat << 'PYTHON' > /home/linuxadmin/app_api.py
from flask import Flask, jsonify
import psycopg2
from azure.storage.blob import BlobServiceClient

app = Flask(__name__)

@app.route('/')
def health_check():
    db_host = "${db_fqdn}"
    db_user = "${db_user}"
    db_pass = "${db_pass}"
    db_name = "postgres"
    conn_uri = f"postgresql://{db_user}:{db_pass}@{db_host}:5432/{db_name}?sslmode=require"

    try:
        conn = psycopg2.connect(conn_uri)
        conn.close()
        db_status = "Successfully connected to PostgreSQL!"
    except Exception as e:
        db_status = f"Database connection failed: {str(e)}"

    storage_account_name = "${storage_name}"
    storage_account_key = "${storage_key}"
    storage_conn_str = f"DefaultEndpointsProtocol=https;AccountName={storage_account_name};AccountKey={storage_account_key};EndpointSuffix=core.windows.net"

    try:
        blob_service_client = BlobServiceClient.from_connection_string(storage_conn_str)
        containers = list(blob_service_client.list_containers())
        storage_status = f"Successfully connected to Azure Blob Storage! Found {len(containers)} container(s)."
    except Exception as e:
        storage_status = f"Storage connection failed: {str(e)}"

    return jsonify({
        "status": "Success",
        "message": "Traffic successfully reached the App Tier!",
        "database_status": db_status,
        "storage_status": storage_status
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYTHON

chown linuxadmin:linuxadmin /home/linuxadmin/app_api.py

cat << 'SERVICE' > /etc/systemd/system/app-api.service
[Unit]
Description=Flask App Tier API
After=network-online.target

[Service]
User=linuxadmin
ExecStart=/usr/bin/python3 /home/linuxadmin/app_api.py
Restart=always
RestartSec=5
StandardOutput=append:/home/linuxadmin/app.log
StandardError=append:/home/linuxadmin/app.log

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now app-api.service