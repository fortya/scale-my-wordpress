#!/bin/bash
# worker-nginx
sudo yum update -y

sudo groupadd ${nginx_group}
sudo usermod -a -G ${nginx_group} ${nginx_user}

sudo yum install -y nfs-utils

sudo yum remove httpd* php* -y
sudo yum install nginx -y

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
sudo yum install php-pecl-memcached -y

# Load Config Files
mkdir -p /etc/nginx/sites-available
sudo echo "${conf_nginx}" > /etc/nginx/nginx.conf
sudo echo "${conf_nginx_wordpress}" > /etc/nginx/sites-available/wordpress
sudo echo "${conf_www}" > /etc/php-fpm.d/www.conf
sudo echo "${conf_php}" > /etc/php-fpm.conf
sudo echo -e "${bootstrap}" > /var/www/html/bootstrap.sh

# wait for file system DNS name to be propagated
results=1
while [[ $results != 0 ]]; do
  nslookup ${efs_dnsname}
  results=$$?
  if [[ results = 1 ]]; then
    sleep 30
  fi
done

mkdir -p ${app_root}
sudo chown -R ${nginx_user}:${nginx_group} ${app_root}
sudo echo "${efs_dnsname}:/ ${app_root} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=24,_netdev 0 0" >> /etc/fstab
sudo mount -a -t nfs4
echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
* * * * * root mount -a -t nfs4
" > /etc/cron.d/mount_efs

# START WEBSERVER
sudo chkconfig httpd on
sudo chkconfig php-fpm on
sudo service nginx start
sudo service php-fpm start

# S3 BACKUP
echo "
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
HOME=/
* * * * * root aws s3 sync ${app_root}/wp-content/ s3://${static_content_bucket}/wp-content/
*/5 * * * * root aws s3 sync ${app_root}/wp-includes/ s3://${static_content_bucket}/wp-includes/
*/5 * * * * root aws s3 sync ${app_root}/wp-config/ s3://${wordpress_config_bucket} --exclude "wp-content/*" --exclude "wp-includes/*"
" > /etc/cron.d/backup_to_s3
