output "wpassets-bucket" {
  value = "${aws_s3_bucket.wp-content.id}"
}

output "wpconfig-bucket" {
  value = "${aws_s3_bucket.wp-config.id}"
}

output "cloudfront-dnsname" {
  value = "${aws_cloudfront_distribution.s3_distribution.domain_name }"
}
