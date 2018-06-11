module "efs" {
  source    = "git::https://github.com/okio/terraform-aws-efs.git?ref=master"
  name      = "${var.app_instance}"
  namespace = "${var.app_name}"
  stage     = "${var.app_stage}-wpconfig"

  aws_region = "${var.aws_region}"
  vpc_id     = "${module.vpc.vpc_id}"
  subnets    = ["${module.vpc.public_subnets}"]

  availability_zones = ["${var.azs}"]
  security_groups    = ["${aws_security_group.webserver.id}"]

  zone_id = "${var.hosted_zone_id}"
}

module "efs-wpinclude" {
  source    = "git::https://github.com/okio/terraform-aws-efs.git?ref=master"
  name      = "${var.app_instance}"
  namespace = "${var.app_name}-wpinclude"
  stage     = "${var.app_stage}"

  aws_region = "${var.aws_region}"
  vpc_id     = "${module.vpc.vpc_id}"
  subnets    = ["${module.vpc.public_subnets}"]

  availability_zones = ["${var.azs}"]
  security_groups    = ["${aws_security_group.webserver.id}"]

  zone_id = "${var.hosted_zone_id}"
}
