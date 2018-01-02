user nginx ${nginx_group};
worker_processes auto;
worker_rlimit_nofile 8192;
pid /var/run/nginx.pid;

events {
	worker_connections 8000;
	multi_accept on;
}

http {
	# HTTP
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	# MIME Types
	types {
	      text/html                             html htm shtml;
	      text/css                              css;
	      text/xml                              xml;
	      image/gif                             gif;
	      image/jpeg                            jpeg jpg;
	      application/javascript                js;
	      application/atom+xml                  atom;
	      application/rss+xml                   rss;
	      text/mathml                           mml;
	      text/plain                            txt;
	      text/vnd.sun.j2me.app-descriptor      jad;
	      text/vnd.wap.wml                      wml;
	      text/x-component                      htc;
	      image/png                             png;
	      image/tiff                            tif tiff;
	      image/vnd.wap.wbmp                    wbmp;
	      image/x-icon                          ico;
	      image/x-jng                           jng;
	      image/x-ms-bmp                        bmp;
	      image/svg+xml                         svg svgz;
	      image/webp                            webp;
	      application/font-woff                 woff;
	      application/java-archive              jar war ear;
	      application/json                      json;
	      application/mac-binhex40              hqx;
	      application/msword                    doc;
	      application/pdf                       pdf;
	      application/postscript                ps eps ai;
	      application/rtf                       rtf;
	      application/vnd.apple.mpegurl         m3u8;
	      application/vnd.ms-excel              xls;
	      application/vnd.ms-fontobject         eot;
	      application/vnd.ms-powerpoint         ppt;
	      application/vnd.wap.wmlc              wmlc;
	      application/vnd.google-earth.kml+xml  kml;
	      application/vnd.google-earth.kmz      kmz;
	      application/x-7z-compressed           7z;
	      application/x-cocoa                   cco;
	      application/x-java-archive-diff       jardiff;
	      application/x-java-jnlp-file          jnlp;
	      application/x-makeself                run;
	      application/x-perl                    pl pm;
	      application/x-pilot                   prc pdb;
	      application/x-rar-compressed          rar;
	      application/x-redhat-package-manager  rpm;
	      application/x-sea                     sea;
	      application/x-shockwave-flash         swf;
	      application/x-stuffit                 sit;
	      application/x-tcl                     tcl tk;
	      application/x-x509-ca-cert            der pem crt;
	      application/x-xpinstall               xpi;
	      application/xhtml+xml                 xhtml;
	      application/xspf+xml                  xspf;
	      application/zip                       zip;
	      application/octet-stream              bin exe dll;
	      application/octet-stream              deb;
	      application/octet-stream              dmg;
	      application/octet-stream              iso img;
	      application/octet-stream              msi msp msm;
	      application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
	      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
	      application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;
	      audio/midi                            mid midi kar;
	      audio/mpeg                            mp3;
	      audio/ogg                             ogg;
	      audio/x-m4a                           m4a;
	      audio/x-realaudio                     ra;
	      video/3gpp                            3gpp 3gp;
	      video/mp2t                            ts;
	      video/mp4                             mp4;
	      video/mpeg                            mpeg mpg;
	      video/quicktime                       mov;
	      video/webm                            webm;
	      video/x-flv                           flv;
	      video/x-m4v                           m4v;
	      video/x-mng                           mng;
	      video/x-ms-asf                        asx asf;
	      video/x-ms-wmv                        wmv;
	      video/x-msvideo                       avi;
	}
	default_type application/octet-stream;

	# Limits and Timeouts
	keepalive_timeout 15;
	send_timeout 30;

	client_body_timeout 30;
	client_body_buffer_size  128k;
	client_max_body_size 64m;

	client_header_timeout 30;
	client_header_buffer_size 3m;

	large_client_header_buffers 4 256k;

	# can cause 500 HTTP erros if these values aren't increased.
	fastcgi_buffers 16 16k;
	fastcgi_buffer_size 32k;

	server_names_hash_bucket_size 128;
        server_names_hash_max_size 512;

	# Default Logs
	error_log /var/log/nginx/error.log warn;
	access_log /var/log/nginx/access.log;

	# Gzip
	gzip on;
	gzip_disable \"msie6\";
	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 5;
	gzip_http_version 1.0;
	gzip_min_length 256;
	gzip_types
		application/atom+xml
		application/javascript
		application/json
		application/ld+json
		application/manifest+json
		application/rss+xml
		application/vnd.geo+json
		application/vnd.ms-fontobject
		application/x-javascript
		application/x-font-ttf
		application/x-web-app-manifest+json
		application/xhtml+xml
		application/xml
		font/opentype
		image/bmp
		image/svg+xml
		image/x-icon
		text/cache-manifest
		text/css
		text/plain
		text/vcard
		text/vnd.rim.location.xloc
		text/vtt
		text/x-component

	# Modules
	include /etc/nginx/conf.d/*.conf;

	# limit the number of connections per single IP
	limit_conn_zone \$$http_x_forwarded_for zone=conn_limit_per_ip:10m;

	# limit the number of requests for a given session
	limit_req_zone \$$http_x_forwarded_for zone=req_limit_per_ip:10m rate=5r/s;

	# Sites
	include /etc/nginx/sites-available/wordpress;

}
