fastcgi_cache_path /var/run/nginx-cache levels=1:2 keys_zone=${app_name}.${app_instance}:100m inactive=60m;
fastcgi_cache_key \"\$$scheme\$$request_method\$$host\$$request_uri\";

upstream php {
        #server unix:/tmp/php-cgi.socket;
        server 127.0.0.1:9000;
}

server {
          listen       80;

          server_name  ${app_domain_name};

          root ${app_root};
          index index.php;

          access_log /var/log/nginx/${app_name}.${app_instance}.access.log;
          error_log  /var/log/nginx/${app_name}.${app_instance}.error.log;

    	    gzip_static on;

      	  #fastcgi_cache start
      	  set \$$no_cache 0;

      	  # POST requests and urls with a query string should always go to PHP
      	  if (\$$request_method = POST) {
                   set \$$no_cache 1;
      	  }
      	  if (\$$query_string != \"\") {
                   set \$$no_cache 1;
      	  }

      	  # Don't cache uris containing the following segments
      	  if (\$$request_uri ~* (/wp-admin/|/xmlrpc.php|/wp-(app|cron|login|register|mail).php|wp-.*.php|/feed/|index.php|wp-comments-popup.php|wp-links-opml.php|wp-locations.php|sitemap(_index)?.xml|[a-z0-9_-]+-sitemap([0-9]+)?.xml)) {
                   set \$$no_cache 1;
      	  }

      	  # Don't use the cache for logged in users or recent commenters
      	  if (\$$http_cookie ~* (comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in)) {
                   set \$$no_cache 1;
      	  }


      	  if (!-e \$$request_filename) {
                   rewrite /wp-admin\$$ \$$scheme://\$$host\$$uri/ permanent;
                   rewrite ^(/[^/]+)?(/wp-.*) \$$2 last;
                   rewrite ^(/[^/]+)?(/.*\.php) \$$2 last;
          }

      	  location /elb-status {
              access_log off;
              return 200 '-_-!';

      	  }
          location / {
              try_files \$$uri \$$uri/ /index.php?\$$args;
          }

          location ~ \.php\$$ {
              try_files \$$uri =404;
              include /etc/nginx/fastcgi_params;

              fastcgi_intercept_errors on;
              fastcgi_cache_bypass \$$no_cache;
              fastcgi_no_cache \$$no_cache;
              fastcgi_cache ${app_name}.${app_instance};
              fastcgi_cache_valid 200 60m;

              fastcgi_pass_header Set-Cookie;
              fastcgi_pass_header Cookie;
              fastcgi_ignore_headers Cache-Control Expires Set-Cookie;

              fastcgi_read_timeout            3600s;
              fastcgi_buffer_size             128k;
              fastcgi_buffers                 4 128k;
              fastcgi_param                   SCRIPT_FILENAME \$$document_root\$$fastcgi_script_name;
              fastcgi_pass php;
          }

      	  location ~* .(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|css|rss|atom|js|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)\$$ {
              	   expires max;
             		   log_not_found off;
              	   access_log off;
          }

      	  location ~* \.(js|css|png|jpg|jpeg|gif|ico)\$$ {
                    expires max;
                    log_not_found off;
          }

      	  location = /favicon.ico {
              log_not_found off;
              access_log off;
      	  }

       	  location = /robots.txt {
              allow all;
              log_not_found off;
      		    access_log off;
          }

      	  location ~ /\. {
      	  	   deny all;
      	  }

}
