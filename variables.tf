variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "us-west-2"
}

variable "mysql_user" {
  default = "wordpress"
}
variable "mysql_pass" {}


variable "app_name" {
  default = "scalepress"
}
variable "app_instance" {}
variable "app_stage" {
  default = "dev"
}

variable "secret_login_path" {}
variable "secret_admin_path" {}

variable "hosted_zone_id" {}
variable "elb_dns_alias" {}

variable "cloudfront_ssl_arn" {}
variable "elb_ssl_arn" {}


variable "ssh_key_name" {}
variable "ssh_whitelist_ip" {}

variable "azs" {
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
  #default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "nginx_user" {
  default = "ec2-user"
}

variable "nginx_group" {
  default = "webserver"
}

variable "wordpress_user" {
  default = "scalepress"
}

variable "wordpress_pass" { }
variable "wordpress_admin_email" { }

variable "wp-path" {
  default = "/var/www/html/htdocs/wordpress"
}
