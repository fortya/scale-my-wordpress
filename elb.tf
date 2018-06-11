resource "aws_elb" "main" {
  name       = "${var.app_name}-${var.app_instance}-${var.app_stage}-elb"
  depends_on = ["aws_s3_bucket_policy.wp-logs"]

  subnets         = ["${module.vpc.public_subnets}"]
  security_groups = ["${aws_security_group.elb.id}"]

  access_logs {
    bucket        = "${aws_s3_bucket.wp-logs.id}"
    bucket_prefix = "ELB"
    interval      = 5
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.elb_ssl_arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/health.html"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Terraform = "true"
    Stage     = "${var.app_stage}"
    App       = "${var.app_name}"
    Instance  = "${var.app_instance}"
  }
}
