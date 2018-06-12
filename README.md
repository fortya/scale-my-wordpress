# Scale My WordPress

Security, Availability, Scalability.  

# Security
- VPC
- ELB
- ELB logs to S3
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

# Process
- Backup filesystem
- Backup database
- Provision Infrastructure


Terraform Commands:
```
terraform get
```

```
terraform init|plan|apply|destroy
  -var 'aws_profile='
  -var 'aws_region='
  -var 'aws_role='

  -var 'app_instance='

  -var 'hosted_zone_id='
  -var 'cloudfront_ssl_arn='
  -var 'cloudfront_dns_alias='
  -var 'app_domain='
  -var 'elb_ssl_arn='

  -var 'ssh_key_name='
  -var 'ssh_whitelist_ip'
```


# Requirements
All dns endpoints must be in the same hosted zone


aws s3 sync . s3://scalepress.[instance].[stage].config --exclude "wp-content/*"


# Wordpress Plugins
Hide my Wordpress
SSL Insecure Content Fixer
