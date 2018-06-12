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

  aliases = ["${var.app_domain}"]

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
    path_pattern           = "${var.secret_login_path}*"
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
    path_pattern           = "${var.secret_admin_path}*"
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
