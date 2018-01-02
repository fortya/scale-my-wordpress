##############################################################
# Authentication
##############################################################
provider "aws" {
  access_key  = "${var.aws_access_key}"
  secret_key  = "${var.aws_secret_key}"
  region      = "${var.aws_region}"
  #profile     = "${var.aws_profile}"
  #assume_role {
  #  role_arn = "${var.aws_role_arn}"
  #}
}

##############################################################
# TEMPLATE FILES
##############################################################
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
    app_name	      = "${var.app_name}"
    app_instance      = "${var.app_instance}"

    cdn_domain        = "${var.cloudfront_ssl_arn}"
    app_root          = "${var.wp-path}"
    app_domain_name   = "${var.elb_dns_alias}"
    app_domain_dns    = "${aws_elb.main.dns_name}"
  }
}


data "template_file" "bootstrap" {
  template = "${file("${path.module}/templates/scripts/bootstrap.tpl")}"

  vars {
    app_name	      = "${var.app_name}"
    app_instance      = "${var.app_instance}"
    app_stage         = "${var.app_stage}"

    nginx_user        = "${var.nginx_user}"
    nginx_group       = "${var.nginx_group}"

    mysql_pass        = "${module.rds.this_db_instance_password}"
    mysql_user        = "${module.rds.this_db_instance_username}"
    mysql_host        = "${module.rds.this_db_instance_address}"
    mysql_db          = "${module.rds.this_db_instance_name}"

    wp-path           = "${var.wp-path}"

    app_domain_name   = "${var.elb_dns_alias}"

    wordpress_user    = "${var.wordpress_user}"
    wordpress_pass    = "${var.wordpress_pass}"
  }
}


data "template_file" "sync" {
  template = "${file("${path.module}/templates/scripts/sync.js.tpl")}"

  vars {
    app_name	      = "${var.app_name}"
    app_instance      = "${var.app_instance}"

    app_root          = "${var.wp-path}"

    static_content_bucket   = "${aws_s3_bucket.wp-content.id}"
  }
}

data "template_file" "httpd_conf" {
  template = "${file("${path.module}/templates/config/apache/httpd.conf.tpl")}"

  vars {
    app_root        = "${var.wp-path}"
    app_domain_name = "${var.elb_dns_alias}"
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

    sync_js              = "${data.template_file.sync.rendered}"
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

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}

##############################################################
# CLOUDFRONT
##############################################################
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "${var.app_name}-${var.app_instance}-${var.app_stage}-webserver-identity"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  viewer_certificate {
    acm_certificate_arn            = "${var.cloudfront_ssl_arn}"
    minimum_protocol_version       = "TLSv1.1_2016"
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = true
  }

  origin {
    domain_name = "${aws_elb.main.dns_name}"
    origin_id   = "webserver-origin"

    custom_origin_config {
      https_port             = 443
      http_port              = 80
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  origin {
    domain_name = "${aws_s3_bucket.wp-content.bucket_domain_name}"
    origin_id   = "static-origin"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.app_name}.${var.app_instance}.${var.app_stage}.cdn"

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.wp-logs.bucket_domain_name}"
    prefix          = "cloudfront/"
  }

  aliases = ["${var.elb_dns_alias}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "webserver-origin"

    forwarded_values {
      query_string = true

      headers = ["Host", "Origin"]

      cookies {
        forward           = "whitelist"
        whitelisted_names = ["PHPSESSID", "comment_author_*", "comment_author_email_*", "comment_author_url_*", "wordpress_logged_in*", "wordpress_test_cookie", "wp-settings-*"]
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 31536000
  }

  cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "static-origin"
    path_pattern           = "/wp-content/*"
    viewer_protocol_policy = "allow-all"

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 604800

    forwarded_values {
      query_string = false

      headers = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }
  }

  cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "static-origin"
    path_pattern           = "/wp-includes/*"
    viewer_protocol_policy = "allow-all"

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 604800

    forwarded_values {
      query_string = true

      headers = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }
  }

  cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "webserver-origin"
    path_pattern           = "/wp-login.php*"
    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 604800

    forwarded_values {
      query_string = true

      headers = ["*"]

      cookies {
        forward = "all"

        #whitelisted_names	= ["comment_author_*", "comment_author_email_*", "comment_author_url_*", "wordpress_logged_in*", "wordpress_test_cookie", "wp-settings-*"]
      }
    }
  }

  cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "webserver-origin"
    path_pattern           = "/${var.secret_login_path}.php*"
    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 604800

    forwarded_values {
      query_string = true

      headers = ["*"]

      cookies {
        forward = "all"

        #whitelisted_names	= ["comment_author_*", "comment_author_email_*", "comment_author_url_*", "wordpress_logged_in*", "wordpress_test_cookie", "wp-settings-*"]
      }
    }
  }

  cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "webserver-origin"
    path_pattern           = "/wp-admin/*"
    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 604800

    forwarded_values {
      query_string = true

      headers = ["*"]

      cookies {
        forward = "all"

        #whitelisted_names	= ["comment_author_*", "comment_author_email_*", "comment_author_url_*", "wordpress_logged_in*", "wordpress_test_cookie", "wp-settings-*"]
      }
    }
  }

  cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "webserver-origin"
    path_pattern           = "/{var.secret_admin_path}/*"
    viewer_protocol_policy = "redirect-to-https"

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 604800

    forwarded_values {
      query_string = true

      headers = ["*"]

      cookies {
        forward = "all"

        #whitelisted_names	= ["comment_author_*", "comment_author_email_*", "comment_author_url_*", "wordpress_logged_in*", "wordpress_test_cookie", "wp-settings-*"]
      }
    }
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"

      #locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags {
    Environment = "${var.app_stage}"
  }
}

##############################################################
# STORAGE
##############################################################
resource "aws_s3_bucket" "wp-content" {
  bucket = "${var.app_name}.${var.app_instance}.${var.app_stage}.assets"
  acl    = "public-read"


  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
    "Sid":"PublicReadForGetBucketObjects",
        "Effect":"Allow",
      "Principal": "*",
      "Action":"s3:GetObject",
      "Resource":["arn:aws:s3:::${var.app_name}.${var.app_instance}.${var.app_stage}.assets/*"
      ]
    }
  ]
}
POLICY


  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]

    #expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
    Service     = "wp-assets"
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket" "wp-config" {
  bucket = "${var.app_name}.${var.app_instance}.${var.app_stage}.config"
  acl    = "private"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
    Service     = "wp-config"
  }
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "wp-logs" {
  bucket = "${var.app_name}.${var.app_instance}.${var.app_stage}.logs"
  acl    = "private"


  tags = {
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
    Terraform   = "true"
    Service     = "wp-logs"
  }

}
data "aws_iam_policy_document" "wp-logs" {
  statement {
      sid = "1"
      principals {
        type  = "AWS"
        identifiers = ["${data.aws_elb_service_account.main.arn}"]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = [
        "${aws_s3_bucket.wp-logs.arn}/ELB/AWSLogs/*"
      ]
  }
}
resource "aws_s3_bucket_policy" "wp-logs" {
  bucket = "${aws_s3_bucket.wp-logs.id}"
  policy = "${data.aws_iam_policy_document.wp-logs.json}"
}
##############################################################
# VPC
##############################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.app_name}vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.azs}"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway           = false
  create_database_subnet_group = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

resource "aws_security_group" "webserver" {
  description = "Allow incoming HTTP connections."
  name        = "${var.app_name}-${var.app_stage}-webserver-sg"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_whitelist_ip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

resource "aws_security_group" "efs" {
  description = "Allow incoming EFS connections."
  name        = "${var.app_name}-${var.app_stage}-sg-efs"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = ["${aws_security_group.webserver.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}


resource "aws_security_group" "elb" {
  description = "Allow incoming HTTP(s) connections."
  name        = "${var.app_name}-${var.app_stage}-sg-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

resource "aws_security_group" "rds" {
  description = "Allow internal Mysql connections from ${var.app_name}-VPCs"
  name        = "${var.app_name}-${var.app_instance}-${var.app_stage}-sg-rds"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.webserver.id}"]
  }

  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

##################################################
# Create an IAM role to allow enhanced monitoring
##################################################
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "${var.app_name}-${var.app_instance}-${var.app_stage}-rds-monitoring"
  assume_role_policy = "${data.aws_iam_policy_document.rds_enhanced_monitoring.json}"
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = "${aws_iam_role.rds_enhanced_monitoring.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

##############################################################
# EFS
##############################################################
module "efs" {
  source    = "git::https://github.com/okio/terraform-aws-efs.git?ref=master"
  name      = "${var.app_instance}"
  namespace = "${var.app_name}"
  stage     = "${var.app_stage}-wpconfig"

  aws_region = "${var.aws_region}"
  vpc_id     = "${module.vpc.vpc_id}"
  subnets    = ["${module.vpc.public_subnets}"]

  availability_zones = ["${var.azs}"]
  security_groups    = ["${aws_security_group.webserver.id}"]

  zone_id = "${var.hosted_zone_id}"
}

module "efs-wpinclude" {
  source    = "git::https://github.com/okio/terraform-aws-efs.git?ref=master"
  name      = "${var.app_instance}"
  namespace = "${var.app_name}-wpinclude"
  stage     = "${var.app_stage}"

  aws_region = "${var.aws_region}"
  vpc_id     = "${module.vpc.vpc_id}"
  subnets    = ["${module.vpc.public_subnets}"]

  availability_zones = ["${var.azs}"]
  security_groups    = ["${aws_security_group.webserver.id}"]

  zone_id = "${var.hosted_zone_id}"
}

################################`##############################
# RDS
##############################################################
module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.app_name}-${var.app_instance}-${var.app_stage}-rds"

  engine            = "mysql"
  engine_version    = "5.7.17"
  license_model     = "general-public-license"
  instance_class    = "db.t2.small"
  allocated_storage = 5

  multi_az                = true
  backup_retention_period = 30
  apply_immediately       = true

  name     = "${var.app_name}_${var.app_instance}_${var.app_stage}"
  username = "wordpress"
  password = "${var.mysql_pass}"
  port     = "3306"

  vpc_security_group_ids = ["${aws_security_group.rds.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  monitoring_interval = "30"
  monitoring_role_arn = "${aws_iam_role.rds_enhanced_monitoring.arn}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }

  # DB subnet group
  subnet_ids = ["${module.vpc.public_subnets}"]

  # DB parameter group
  family = "mysql5.7"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${var.app_name}-${var.app_instance}-${var.app_stage}-db"

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    },
  ]
}

##############################################################
# AUTO SCALLING
##############################################################
resource "aws_launch_configuration" "main" {
  #name                 = "${var.app_name}-${var.app_instance}-${var.app_stage}-web-LC"
  image_id             = "${data.aws_ami.amazon_linux.id}"
  instance_type        = "t2.small"
  security_groups      = ["${aws_security_group.webserver.id}"]
  user_data            = "${data.template_file.webserver_asg.rendered}"
  key_name             = "${var.ssh_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.webserver.id}"

  ebs_block_device {
    volume_size = 200
    volume_type = "gp2"
    device_name = "/dev/sdg"
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_launch_configuration" "worker" {
  #name                 = "${var.app_name}-${var.app_instance}-${var.app_stage}-worker-LC"
  image_id             = "${data.aws_ami.amazon_linux.id}"
  instance_type        = "t2.small"
  security_groups      = ["${aws_security_group.webserver.id}"]
  user_data            = "${data.template_file.webserver_worker.rendered}"
  key_name             = "${var.ssh_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.webserver.id}"
  lifecycle { create_before_destroy = true }

  ebs_block_device {
    volume_size = 200
    volume_type = "gp2"
    device_name = "/dev/sdg"
  }
}

resource "aws_autoscaling_group" "main" {
  vpc_zone_identifier       = ["${module.vpc.public_subnets}"]
  name                      = "${var.app_name}-${var.app_instance}-${var.app_stage}-web-asg"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  wait_for_elb_capacity     = "2"
  force_delete              = true

  load_balancers = ["${aws_elb.main.name}"]

  #placement_group           = "${aws_placement_group.main.id}"
  launch_configuration = "${aws_launch_configuration.main.name}"

  tag {
    key                 = "Stage"
    value               = "${var.app_stage}"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = "${var.app_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Instance"
    value               = "${var.app_instance}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-${var.app_instance}-${var.app_stage}-asg"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_cloudwatch_metric_alarm" "CpuMax" {
  alarm_name          = "${var.app_name}-${var.app_instance}-${var.app_stage}-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
  }

  alarm_description = "This metric monitors ec2 max cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.more.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "CpuMin" {
  alarm_name          = "${var.app_name}-${var.app_instance}-${var.app_stage}-scale-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "40"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
  }

  alarm_description = "This metric monitors min ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.less.arn}"]
}

resource "aws_autoscaling_policy" "more" {
  name                   = "${var.app_name}-${var.app_instance}-${var.app_stage}-more"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"
}

resource "aws_autoscaling_policy" "less" {
  name                   = "${var.app_name}-${var.app_instance}-${var.app_stage}-less"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"
}

##############################################################
# INSTANCE PERMISSIONS
##############################################################
resource "aws_iam_role" "web_iam_role" {
  name = "${var.app_name}-${var.app_instance}-${var.app_stage}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "webserver" {
  name = "${var.app_name}-${var.app_instance}-${var.app_stage}-profile"
  role = "${aws_iam_role.web_iam_role.name}"
}

resource "aws_iam_role_policy" "web_iam_role_policy" {
  name = "${var.app_name}-${var.app_instance}-${var.app_stage}-policy"
  role = "${aws_iam_role.web_iam_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["${aws_s3_bucket.wp-content.arn}", "${aws_s3_bucket.wp-config.arn}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["${aws_s3_bucket.wp-content.arn}/*", "${aws_s3_bucket.wp-config.arn}/*"]
    }
  ]
}
EOF
}

##############################################################
# WORKER INSTANCE
##############################################################
module "ec2_cluster" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name  = "${var.app_name}-${var.app_instance}-${var.app_stage}-worker"
  count = 1

  ami                    = "${data.aws_ami.amazon_linux.id}"
  instance_type          = "t2.small"
  key_name               = "${var.ssh_key_name}"
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.webserver.id}"]

  subnet_id = "${element(module.vpc.public_subnets, 0)}"

  user_data = "${data.template_file.webserver_worker.rendered}"

  associate_public_ip_address = true

  iam_instance_profile = "${aws_iam_instance_profile.webserver.id}"

  tags = {
    Terraform = "true"
    App       = "${var.app_name}"
    Stage     = "${var.app_stage}"
    Instance  = "${var.app_instance}"
  }
}

##############################################################
# ELB
##############################################################
resource "aws_elb" "main" {
  name = "${var.app_name}-${var.app_instance}-${var.app_stage}-elb"
  depends_on = ["aws_s3_bucket_policy.wp-logs"]

  subnets         = ["${module.vpc.public_subnets}"]
  security_groups = ["${aws_security_group.elb.id}"]

  access_logs {
    bucket        = "${aws_s3_bucket.wp-logs.id}"
    bucket_prefix = "ELB"
    interval      = 5
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.elb_ssl_arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/health.html"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Terraform = "true"
    Stage     = "${var.app_stage}"
    App       = "${var.app_name}"
    Instance  = "${var.app_instance}"
  }
}
