resource "aws_s3_bucket" "wp-content" {
  bucket = "${var.app_name}.${var.app_instance}.${var.app_stage}.assets"
  acl    = "public-read"

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
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.main.arn}"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.wp-logs.arn}/ELB/AWSLogs/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "wp-logs" {
  bucket = "${aws_s3_bucket.wp-logs.id}"
  policy = "${data.aws_iam_policy_document.wp-logs.json}"
}
