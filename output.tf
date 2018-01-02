output "efs_domain" {
  value = "${module.efs.host}"
}

output "efs_dns_name" {
  value = "${module.efs.dns_name}"
}

output "efs_security_group" {
  value = "${module.efs.security_group}"
}

output "elb_domain" {
  value = "${aws_elb.main.dns_name}"
}

output "content_bucket_id" {
  value = "${aws_s3_bucket.wp-content.id}"
}
