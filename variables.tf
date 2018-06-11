variable "aws_region" {
  description = "In which region you want to launch this wordpress"
  default     = "us-west-2"
}

variable "app_name" {
  description = "Product name."
  default     = "scalepress"
}

variable "app_instance" {
  description = "Application instance name."
}

variable "app_stage" {
  description = "Application stage (ie. Dev, Prod, QA, etc)."
  default     = "dev"
}

variable "secret_login_path" {
  description = "Secret path to login to Wordpress. Defaults to `/login`."
  default     = "login"
}

variable "secret_admin_path" {
  description = "Secret path to login to Wordpress as an admin. Defaults to `/admin`."
  default     = "admin"
}

variable "hosted_zone_id" {
  description = "Hosted Zone Id for Route 53. Used to manage DNS."
}

variable "app_domain" {
  description = "Application domain (ie. wp.example.com)."
}

variable "cloudfront_ssl_arn" {
  description = "ARN for SSL certificate in Cloudfront."
}

variable "elb_ssl_arn" {
  description = "ARN for SSL certificate in ELB."
}

variable "ssh_key_name" {
  description = "Key pair for EC2 instances."
}

variable "ssh_whitelist_ip" {
  type        = "list"
  description = "Whitelisted IP addresses for SSH access to EC2 instances."
}

variable "azs" {
  description = "Availability Zones to launch resources in. Defaults to `us-west-2a` and `us-west-2b`. It must match `aws_region` variable."
  default     = ["us-west-2a", "us-west-2b"]
}

variable "wordpress_user" {
  description = "Wordpress Admin username. Defaults to `scalepress`."
  default     = "scalepress"
}

variable "wordpress_pass" {
  description = "Wordpress Admin password."
}

variable "wordpress_admin_email" {
  description = "Wordpress Admin email."
}

variable "mysql_user" {
  description = "MySQL user for wordpress (defaults to `wordpress`)."
  default     = "wordpress"
}

variable "mysql_pass" {
  description = "MySQL password."
}

variable "ec2_type" {
  description = "EC2 instance types to run. Defaults to `t2.small`."
  default     = "t2.small"
}

variable "nginx_user" {
  description = "User for nginx. Defaults to `ec2-user`."
  default     = "ec2-user"
}

variable "nginx_group" {
  description = "User Group for nginx. Defaults to `webserver`."
  default     = "webserver"
}

variable "wp-path" {
  description = "Path where wordpress is going to be installed."
  default     = "/var/www/html/htdocs/wordpress"
}
