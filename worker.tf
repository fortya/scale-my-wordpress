# module "ec2_cluster" {
#   source = "terraform-aws-modules/ec2-instance/aws"
#   name  = "${var.app_name}-${var.app_instance}-${var.app_stage}-worker"
#   count = 1
#   ami                    = "${data.aws_ami.amazon_linux.id}"
#   instance_type          = "t2.small"
#   key_name               = "${var.ssh_key_name}"
#   monitoring             = true
#   vpc_security_group_ids = ["${aws_security_group.webserver.id}"]
#   subnet_id = "${element(module.vpc.public_subnets, 0)}"
#   user_data = "${data.template_file.webserver_worker.rendered}"
#   associate_public_ip_address = true
#   iam_instance_profile = "${aws_iam_instance_profile.webserver.id}"
#   tags = {
#     Terraform = "true"
#     App       = "${var.app_name}"
#     Stage     = "${var.app_stage}"
#     Instance  = "${var.app_instance}"
#   }
# }

