data "template_file" "nginx" {
  template = "${file("${path.module}/templates/config/nginx/nginx.conf.tpl")}"

  vars {
    nginx_user  = "${var.nginx_user}"
    nginx_group = "${var.nginx_group}"
  }
}

data "template_file" "php_ini" {
  template = "${file("${path.module}/templates/config/php-fpm-7.0.conf.tpl")}"

  vars {
    nginx_user  = "${var.nginx_user}"
    nginx_group = "${var.nginx_group}"
  }
}

data "template_file" "wordpress" {
  template = "${file("${path.module}/templates/config/nginx/wordpress.conf.tpl")}"

  vars {
    app_name     = "${var.app_name}"
    app_instance = "${var.app_instance}"

    cdn_domain      = "${var.cloudfront_ssl_arn}"
    app_root        = "${var.wp-path}"
    app_domain_name = "${var.app_domain}"
    app_domain_dns  = "${aws_elb.main.dns_name}"
  }
}

data "template_file" "bootstrap" {
  template = "${file("${path.module}/templates/scripts/bootstrap.tpl")}"

  vars {
    app_name     = "${var.app_name}"
    app_instance = "${var.app_instance}"
    app_stage    = "${var.app_stage}"

    nginx_user  = "${var.nginx_user}"
    nginx_group = "${var.nginx_group}"

    mysql_pass = "${module.rds.this_db_instance_password}"
    mysql_user = "${module.rds.this_db_instance_username}"
    mysql_host = "${module.rds.this_db_instance_address}"
    mysql_db   = "${module.rds.this_db_instance_name}"

    wp-path = "${var.wp-path}"

    app_domain_name = "${var.app_domain}"

    wordpress_admin_user  = "${var.wordpress_user}"
    wordpress_admin_pass  = "${var.wordpress_pass}"
    wordpress_admin_email = "${var.wordpress_admin_email}"
  }
}

data "template_file" "sync" {
  template = "${file("${path.module}/templates/scripts/sync.js.tpl")}"

  vars {
    app_name     = "${var.app_name}"
    app_instance = "${var.app_instance}"

    app_root = "${var.wp-path}"

    static_content_bucket = "${aws_s3_bucket.wp-content.id}"
  }
}

data "template_file" "httpd_conf" {
  template = "${file("${path.module}/templates/config/apache/httpd.conf.tpl")}"

  vars {
    app_root        = "${var.wp-path}"
    app_domain_name = "${var.app_domain}"
  }
}

data "template_file" "www_conf" {
  template = "${file("${path.module}/templates/config/www.conf.tpl")}"

  vars {
    nginx_user  = "${var.nginx_user}"
    nginx_group = "${var.nginx_group}"
  }
}

data "template_file" "webserver_asg" {
  template = "${file("${path.module}/templates/launch/server_asg_nginx.tpl")}"

  vars {
    app_name     = "${var.app_name}"
    app_instance = "${var.app_instance}"
    app_root     = "${var.wp-path}"
    app_stage    = "${var.app_stage}"

    efs_dnsname = "${module.efs.dns_name}"
    efs_host    = "${module.efs.host}"

    efs_wpinclude_dnsname = "${module.efs-wpinclude.dns_name}"
    efs_wpinclude_host    = "${module.efs-wpinclude.host}"

    static_content_bucket   = "${aws_s3_bucket.wp-content.id}"
    wordpress_config_bucket = "${aws_s3_bucket.wp-config.id}"

    nginx_user           = "${var.nginx_user}"
    nginx_group          = "${var.nginx_group}"
    conf_nginx           = "${data.template_file.nginx.rendered}"
    conf_nginx_wordpress = "${data.template_file.wordpress.rendered}"
    conf_www             = "${data.template_file.www_conf.rendered}"
    conf_httpd           = "${data.template_file.httpd_conf.rendered}"
    conf_php             = "${data.template_file.php_ini.rendered}"

    sync_js = "${data.template_file.sync.rendered}"
  }
}

data "template_file" "webserver_worker" {
  template = "${file("${path.module}/templates/launch/server_worker.tpl")}"

  vars {
    app_name     = "${var.app_name}"
    app_instance = "${var.app_instance}"
    app_root     = "${var.wp-path}"
    app_stage    = "${var.app_stage}"

    efs_dnsname = "${module.efs.dns_name}"
    efs_host    = "${module.efs.host}"

    efs_wpinclude_dnsname = "${module.efs-wpinclude.dns_name}"
    efs_wpinclude_host    = "${module.efs-wpinclude.host}"

    static_content_bucket   = "${aws_s3_bucket.wp-content.id}"
    wordpress_config_bucket = "${aws_s3_bucket.wp-config.id}"

    nginx_user  = "${var.nginx_user}"
    nginx_group = "${var.nginx_group}"

    conf_nginx           = "${data.template_file.nginx.rendered}"
    conf_nginx_wordpress = "${data.template_file.wordpress.rendered}"
    conf_www             = "${data.template_file.www_conf.rendered}"
    sync_js              = "${data.template_file.sync.rendered}"
    conf_php             = "${data.template_file.php_ini.rendered}"
    conf_httpd           = "${data.template_file.httpd_conf.rendered}"
    bootstrap            = "${data.template_file.bootstrap.rendered}"
  }
}
