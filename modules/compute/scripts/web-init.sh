# #!/bin/bash
# apt-get update
# apt-get install -y nginx

# cat << 'EOF' > /etc/nginx/sites-available/default
# server {
#     listen 80 default_server;
#     listen [::]:80 default_server;

#     location / {
#         proxy_pass http://${internal_lb_ip}:8080;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#     }
# }
# EOF

# systemctl restart nginx






#!/bin/bash

# Stop the background updater before it can grab the dpkg lock
systemctl stop apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
systemctl disable apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
systemctl mask apt-daily.service apt-daily-upgrade.service 2>/dev/null || true

wait_for_apt() {
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
     || sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 \
     || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    sleep 5
  done
}

wait_for_apt
apt-get update

wait_for_apt
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