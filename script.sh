#!/bin/bash
yum install nginx -y
echo "<html><body><h1>&#128570;&#128075;</h1><p>Carrol the cat says hello from private instance ${instance_id}</p></body></html>" > /usr/share/nginx/html/index.html
systemctl start nginx
