#!/usr/bin/env bashs

# Install nginx
amazon-linux-extras enable nginx1
yum clean metadata
yum install nginx -y

# Enable and start nginx.service
systemctl enable nginx
systemctl start nginx
