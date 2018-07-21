resource "aws_launch_configuration" "main" {
  #name                 = "${var.app_name}-${var.app_instance}-${var.app_stage}-worker-LC"
  image_id             = "${data.aws_ami.amazon_linux.id}"
  instance_type        = "t2.small"
  security_groups      = ["${aws_security_group.webserver.id}"]
  user_data            = "${data.template_file.webserver.rendered}"
  key_name             = "${var.ssh_key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.webserver.id}"

  lifecycle {
    create_before_destroy = true
  }

  ebs_block_device {
    volume_size = 200
    volume_type = "gp2"
    device_name = "/dev/sdg"
  }
}

resource "aws_autoscaling_group" "main" {
  vpc_zone_identifier       = ["${module.vpc.public_subnets}"]
  name                      = "${var.app_name}-${var.app_instance}-${var.app_stage}-web-asg"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  wait_for_elb_capacity     = "2"
  force_delete              = true

  load_balancers = ["${aws_elb.main.name}"]

  #placement_group           = "${aws_placement_group.main.id}"
  launch_configuration = "${aws_launch_configuration.main.name}"

  tag {
    key                 = "Stage"
    value               = "${var.app_stage}"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = "${var.app_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Instance"
    value               = "${var.app_instance}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-${var.app_instance}-${var.app_stage}-asg"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "CpuMax" {
  alarm_name          = "${var.app_name}-${var.app_instance}-${var.app_stage}-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
  }

  alarm_description = "This metric monitors ec2 max cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.more.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "CpuMin" {
  alarm_name          = "${var.app_name}-${var.app_instance}-${var.app_stage}-scale-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "40"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
  }

  alarm_description = "This metric monitors min ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.less.arn}"]
}

resource "aws_autoscaling_policy" "more" {
  name                   = "${var.app_name}-${var.app_instance}-${var.app_stage}-more"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"
}

resource "aws_autoscaling_policy" "less" {
  name                   = "${var.app_name}-${var.app_instance}-${var.app_stage}-less"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"
}
