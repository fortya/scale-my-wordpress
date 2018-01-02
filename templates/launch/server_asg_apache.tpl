#!/bin/bash
sudo yum update -y

# System User Permissions
sudo groupadd ${nginx_group}
sudo useradd -G ec2-user,${nginx_user} ${nginx_group}

# EFS
sudo yum install -y nfs-utils

# Remove current apache & php
sudo yum remove httpd* php* -y

# Install PHP 7.0
# automatically includes php70-cli php70-common php70-json php70-process php70-xml
sudo yum install php70 -y
sudo yum install php70-fpm -y

# Install additional commonly used php packages
sudo yum install php70-gd -y
sudo yum install php70-imap -y
sudo yum install php70-mbstring -y
sudo yum install php70-mysqlnd -y
sudo yum install php70-opcache -y
sudo yum install php70-pdo -y
sudo yum install php70-pecl-apcu -y

# Wordpress Config
aws s3 sync s3://${wordpress_config_bucket} ${app_root} --exclude "wp-content/*" --exclude "wp-includes/*"
aws s3 sync s3://${static_content_bucket}/wp-includes/ ${app_root}/wp-includes
sudo echo "-_-" >> ${app_root}/health.html

sudo chmod 660 ${app_root}/wp-config.php
sudo mkdir -p ${app_root}/wp-content
#sudo find ${nginx_user} -exec chown ${nginx_user}:${nginx_group} {} +
sudo find ${app_root} -type f -exec chmod 644 {} +
sudo find ${app_root} -type d -exec chmod 755 {} +
sudo chown -R ${nginx_user}:${nginx_group} ${app_root}

# Load latest from S3
echo "
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
* * * * * root aws s3 sync s3://${static_content_bucket}/wp-includes/ ${app_root}/wp-includes/
" > /etc/cron.d/s3_to_fs

# Push Latest to S3
echo "
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
* * * * * root aws s3 sync ${app_root}/wp-includes/ s3://${static_content_bucket}/wp-includes/
" > /etc/cron.d/fs_to_s3

# Mount EFS
sudo echo "${efs_dnsname}:/ ${app_root}/wp-content nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=24,_netdev 0 0" >> /etc/fstab
sudo mount -a -t nfs4

# Keep EFS mounted
echo "
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
* * * * * root mount -a -t nfs4
" > /etc/cron.d/mount_efs

sudo echo "${conf_httpd}" > /etc/httpd/conf/httpd.conf

sudo chkconfig httpd on
sudo chkconfig php-fpm on

sudo service php-fpm start
sudo service httpd start
