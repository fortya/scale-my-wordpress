# create hidden opcache directory locally & change owner to apache
if [ ! -d ${wp-path}/.opcache ]; then
    mkdir -p ${wp-path}/.opcache
fi
enable opcache in /etc/php-5.5.d/opcache.ini
#sed -i 's/;opcache.file_cache=.*/opcache.file_cache=\/var\/www\/.opcache/' /etc/php-5.5.d/opcache.ini
#sed -i 's/opcache.memory_consumption=.*/opcache.memory_consumption=512/' /etc/php-5.5.d/opcache.ini
# download opcache-instance.php to verify opcache status
if [ ! -f /var/www/wordpress/opcache-instanceid.php ]; then
    wget -P /var/www/wordpress/ https://s3.amazonaws.com/aws-refarch/wordpress/latest/bits/opcache-instanceid.php
fi
