# install wp-cli
if [ ! -f /bin/wp/wp-cli.phar ]; then
   curl -o /bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
   chmod +x /bin/wp
fi

# Install Wordpress
if [ ! -d ${wp-path} ]; then
   mkdir -p ${wp-path}
   
   yum install -y mysql

   cd ${wp-path}
   # install wordpress if not installed
   # use public alb host name if wp domain name was empty
   if ! $$(wp core is-installed --allow-root); then
       sudo -u ${nginx_user} -i -- wp core download --locale='en_GB' --path='${wp-path}' --allow-root
       sudo -u ${nginx_user} -i -- wp core config --dbname='${mysql_db}' --dbuser='${mysql_user}' --dbpass='${mysql_pass}' --dbhost='${mysql_host}' --path='${wp-path}'
       sudo -u ${nginx_user} -i -- wp core install --url='${app_domain_name}' --title='Scalepress v1.05' --admin_user='${wordpress_user}' --admin_password='${wordpress_pass}' --path='${wp-path}' --admin_email='admin@email.com'

       if [ ! -f ${wp-path}/opcache-instanceid.php ]; then
         wget -P ${wp-path}/ https://s3.amazonaws.com/aws-refarch/wordpress/latest/bits/opcache-instanceid.php
       fi

       #wp plugin install hide-my-wp --activate
       wp plugin install ssl-insecure-content-fixer --activate
       wp plugin install use-google-libraries --activate
       wp plugin install google-webfont-optimizer --activate
       wp plugin install w3-total-cache --activate

       # set permissions of wordpress site directories
       chown -R ${nginx_user}:${nginx_group} ${wp-path}
       chmod u+wrx ${wp-path}/wp-content/*
   fi
   RESULT=$$?
   if [ $$RESULT -eq 0 ]; then
       touch ${wp-path}/wordpress.initialized
         else
       touch ${wp-path}/wordpress.failed
   fi
fi

# TODO: update bucket policy