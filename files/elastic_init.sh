#!/bin/bash

# LOG OUTPUT TO A FILE
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/root/.elastic_automate/log.out 2>&1

if [[ ! -f "/root/.elastic_automate/init.cfg" ]]
then
  # Run elastic install script
  cp /root/.elastic_automate/elasticsearch.yml /etc/elasticsearch/
  cp /root/.elastic_automate/elasticsearch /etc//etc/default/
  # Set security limits
  cat > /etc/security/limits.conf << EOF
elasticsearch soft memlock unlimited
elasticsearch hard memlock unlimited
EOF
  # Increase mmap counts
  echo "vm.max_map_count=262144" >> /etc/sysctl.conf
  # Make permanent
  sysctl -p /etc/sysctl.conf
  # Start elasticsearch
  systemctl enable elasticsearch
  systemctl start elasticsearch
  # COPY req.conf into /etc/nginx/req.conf
  cp /root/.elastic_automate/req.conf /etc/nginx/req.conf
  # COPY default into /etc/nginx/sites-available/default
  cp /root/.elastic_automate/default /etc/nginx/sites-available/default
  # GENERATE SELF SIGNED CERTIFICATES FOR NGINX REVERSE PROXY
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/nginx.key -out /etc/nginx/nginx.crt -config /etc/nginx/req.conf
  # GENERATE STRONG DIFFIEHELMAN PARAMS
  openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
  # RESTART nginx
  systemctl restart nginx
  # CHECK NGINX STATUS
  systemctl status nginx
  # Idempotentcy
  touch /root/.elastic_automate/init.cfg
fi
