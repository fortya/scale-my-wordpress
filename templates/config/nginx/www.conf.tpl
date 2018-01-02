[www]
listen = 127.0.0.1:9000
user = ${nginx_user}
group = ${nginx_group}
listen.allowed_clients = 127.0.0.1

listen.owner = ${nginx_user}
listen.group = ${nginx_group}
listen.mode = 0664

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

slowlog = /var/log/php-fpm/www-slow.log

php_admin_value[error_log] = /var/log/php-fpm/7.0/www-error.log
php_admin_flag[log_errors] = on

php_admin_value[post_max_size] = 64M
php_admin_value[upload_max_filesize] = 64M

php_value[session.save_handler] = files
