#!/bin/bash
apt-get update
apt-get install -y python3-pip
pip3 install flask psycopg2-binary azure-storage-blob

cat << 'PYTHON' > /home/linuxadmin/app_api.py
from flask import Flask, jsonify
import psycopg2
from azure.storage.blob import BlobServiceClient

app = Flask(__name__)

@app.route('/')
def health_check():
    # --- 1. Test PostgreSQL Connection ---
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

    # --- 2. Test Blob Storage Connection ---
    storage_account_name = "${storage_name}"
    storage_account_key = "${storage_key}"
    storage_conn_str = f"DefaultEndpointsProtocol=https;AccountName={storage_account_name};AccountKey={storage_account_key};EndpointSuffix=core.windows.net"

    try:
        blob_service_client = BlobServiceClient.from_connection_string(storage_conn_str)
        # Fetching the list of containers to prove our secure authentication works
        containers = list(blob_service_client.list_containers())
        storage_status = f"Successfully connected to Azure Blob Storage! Found {len(containers)} container(s)."
    except Exception as e:
        storage_status = f"Storage connection failed: {str(e)}"

    # --- 3. Return Combined JSON Response ---
    return jsonify({
        "status": "Success", 
        "message": "Traffic successfully reached the App Tier!",
        "database_status": db_status,
        "storage_status": storage_status
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYTHON

nohup python3 /home/linuxadmin/app_api.py > /home/linuxadmin/app.log 2>&1 &