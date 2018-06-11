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
