#!/bin/bash

echo "Update then install httpd and efs utils"
yum -y update
yum -y install httpd amazon-efs-utils

# mount EFS
mount -t efs ${efs}:/ /var/www/html

# add mount to fstab
cat <<EOF >>/etc/fstab
${efs}:/   /var/www/html   efs   defaults,_netdev  0  0
EOF


if [ ! -f /var/www/html/wp-config.php ];
then
  install_wp
fi
