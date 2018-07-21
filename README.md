# Scale My WordPress

Security, Availability, Scalability.  

# Security
- VPC
- ELB
- - ELB logs to S3
- WAF
- Nginx Best Practices
- Wordpress Best Practices

# Availability
- ELB
- RDS Multi-AZ
- Cloudfront

# Scalability
- Auto Scaling Group
- Cloudfront

# Disaster Recovery
- Filesystem sync every 60 seconds (EFS->S3)
- Database backups every 24 hours, 30-day retention (RDS)
- Fault Tolerance
- Database failover

# Best Practices- RDS
- snapshot every 24 hours for up to 30 days
- Multi-AZ

# Best Practices - Nginx
- Deny access to uploads that aren’t images, videos, music, etc.
- Deny public access to wp-config.php
- Serve static files from cdn
- Rate limit access to log-in & admin panel
- Configure NGINX for FastCGI

# Best Practices - Wordpress
- Hide Access to admin panel & login page
- Force HTTPS


# Clean Install
1. Deploy with 1 node
2. ssh into node

```
cd /var/www/html
sudo sh bootstrap.sh
```

3. go party you are done


# Migration Process
1. Backup static assets
2. Export posts, users, categories etc ...
3. Provision SMWP Infrastructure


# Backup static assets
- Login to the existing server and cd to the WordPress root directory
- Backup all contents to an S3 bucket 

```
aws s3 sync . s3://smwp.[instance].[stage].config --exclude "wp-content/*"
```


# WordPress Plugins
- hide-my-wp
- ssl-insecure-content-fixer
- use-google-libraries
- google-webfont-optimizer
- w3-total-cache

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| app_domain | Application domain (ie. dev.example.com). | string | - | yes |
| app_instance | Unique deployment id | string | - | yes |
| app_name | Product name. | string | `smwp` | no |
| app_stage | Application stage (ie. Dev, Prod, QA, etc). | string | `dev` | no |
| aws_profile | Which AWS Profile? | string | `default` | no |
| aws_region | Which aws region? (us-west-2, us-west-1 ...) | string | `us-west-2` | no |
| azs | Availability Zones to launch resources in. Defaults to `us-west-2a` and `us-west-2b`. It must match `aws_region` variable. | string | `<list>` | no |
| cloudfront_ssl_arn | ARN for SSL certificate in Cloudfront. | string | - | yes |
| ec2_type | EC2 instance types to run. Defaults to `t2.small`. | string | `t2.small` | no |
| elb_ssl_arn | ARN for SSL certificate in ELB. | string | - | yes |
| hosted_zone_id | Hosted Zone Id for Route 53. Used to manage DNS. | string | - | yes |
| mysql_pass | MySQL password. | string | - | yes |
| mysql_user | MySQL user for wordpress (defaults to `wordpress`). | string | `wordpress` | no |
| nginx_group | User Group for nginx. Defaults to `webserver`. | string | `webserver` | no |
| nginx_user | User for nginx. Defaults to `ec2-user`. | string | `ec2-user` | no |
| secret_admin_path | Secret path to login to Wordpress as an admin. Defaults to `/admin`. | string | `admin` | no |
| secret_login_path | Secret path to login to Wordpress. Defaults to `/login`. | string | `login` | no |
| ssh_key_name | Key pair for EC2 instances. | string | - | yes |
| ssh_whitelist_ip | Whitelisted IP addresses for SSH access to EC2 instances. | list | - | yes |
| wordpress_admin_email | Wordpress Admin email. | string | - | yes |
| wordpress_pass | Wordpress Admin password. | string | - | yes |
| wordpress_user | Wordpress Admin username. Defaults to `scalepress`. | string | `scalepress` | no |
| wp-path | Path where wordpress is going to be installed. | string | `/var/www/html/htdocs/wordpress` | no |


## Outputs

| Name | Description |
|------|-------------|
| efs_security_group |  |
| elb-dns_name |  |
| wpconfig-dns_name |  |
| wpconfig-host |  |
| wpcontent-bucket |  |



# TODO:
- Use provisioned iOPS with EFS
- Fix sync.js.tpl and remove cron backup job
- Warning: aws_cloudfront_distribution.s3_distribution: "cache_behavior": [DEPRECATED] Use `ordered_cache_behavior` instead