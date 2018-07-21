module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.app_name}vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.azs}"]
  private_subnets = ["${var.private_subnets}"]
  public_subnets  = ["${var.public_subnets}"]

  enable_nat_gateway           = false
  create_database_subnet_group = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

resource "aws_security_group" "webserver" {
  description = "Allow incoming HTTP connections."
  name        = "${var.app_name}-${var.app_stage}-webserver-sg"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_whitelist_ip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

resource "aws_security_group" "efs" {
  description = "Allow incoming EFS connections."
  name        = "${var.app_name}-${var.app_stage}-sg-efs"

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = ["${aws_security_group.webserver.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

resource "aws_security_group" "elb" {
  description = "Allow incoming HTTP(s) connections."
  name        = "${var.app_name}-${var.app_stage}-sg-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

resource "aws_security_group" "rds" {
  description = "Allow internal Mysql connections from ${var.app_name}-VPCs"
  name        = "${var.app_name}-${var.app_instance}-${var.app_stage}-sg-rds"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.webserver.id}"]
  }

  vpc_id = "${module.vpc.vpc_id}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }
}

##################################################
# Create an IAM role to allow enhanced monitoring
##################################################
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "${var.app_name}-${var.app_instance}-${var.app_stage}-rds-monitoring"
  assume_role_policy = "${data.aws_iam_policy_document.rds_enhanced_monitoring.json}"
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = "${aws_iam_role.rds_enhanced_monitoring.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}
