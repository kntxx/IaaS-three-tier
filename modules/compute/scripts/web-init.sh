#!/bin/bash
apt-get update
apt-get install -y nginx

cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    location / {
        proxy_pass http://${internal_lb_ip}:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

systemctl restart nginx