module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.app_name}-${var.app_instance}-${var.app_stage}-rds"

  engine            = "mysql"
  engine_version    = "5.7.17"
  license_model     = "general-public-license"
  instance_class    = "db.t2.small"
  allocated_storage = 5

  multi_az                = true
  backup_retention_period = 30
  apply_immediately       = true

  name     = "${var.app_name}_${var.app_instance}_${var.app_stage}"
  username = "wordpress"
  password = "${var.mysql_pass}"
  port     = "3306"

  vpc_security_group_ids = ["${aws_security_group.rds.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  monitoring_interval = "30"
  monitoring_role_arn = "${aws_iam_role.rds_enhanced_monitoring.arn}"

  tags = {
    Terraform   = "true"
    Environment = "${var.app_stage}"
    App         = "${var.app_name}"
    Instance    = "${var.app_instance}"
  }

  # DB subnet group
  subnet_ids = ["${module.vpc.public_subnets}"]

  # DB parameter group
  family = "mysql5.7"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${var.app_name}-${var.app_instance}-${var.app_stage}-db"

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    },
  ]
}
