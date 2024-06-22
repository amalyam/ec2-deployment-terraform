#!/bin/bash
yum install nginx -y
echo "Hello World" > /usr/share/nginx/html/index.html
systemctl start nginx
