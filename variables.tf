variable "aws_region" {
  description = "Which aws region? (us-west-2, us-west-1 ...) "
  default     = "us-west-2"
}

variable "aws_profile" {
  type        = "string"
  description = "Which AWS Profile"
  default     = "default"
}

variable "app_name" {
  description = "Solution Identifier"
  default     = "smwp"
}

variable "app_version" {
  default = "1.0.6"
}

variable "app_instance" {
  description = "Unique deployment id"
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
  description = "Application domain (ie. dev.example.com)"
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
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnets" {
  description = "Ip range for VPC private_subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "Ip range for VPC public_subnets"
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
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
