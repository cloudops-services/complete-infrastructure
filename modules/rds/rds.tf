data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_secretsmanager_secret" "database_secret" {
  arn = "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:${var.secrets_path}"
}

data "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = data.aws_secretsmanager_secret.database_secret.id
}

resource "aws_db_subnet_group" "rds_db_application_subnet" {
  name       = "${var.project}-${var.environment}"
  subnet_ids = var.subnets
  tags = {
    "Name"      = "${var.maintainer}-${var.project}-${var.environment}"
    "ManagedBy" = "${var.maintainer}-terraform"
  }
}

resource "aws_security_group" "allow_vpc_traffic" {
  name        = "${var.environment}-${var.project}-allow-vpc-traffic"
  description = "Allow ${var.environment} inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow ingress from ${var.environment} VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow-db-${var.environment}-${var.project}"
  }
}

resource "aws_db_instance" "rds_application_instance" {

  allocated_storage                   = 80
  engine                              = "mysql"
  engine_version                      = "8.0.35"
  instance_class                      = var.instance_type
  identifier                          = "${var.project}-${var.environment}-db"
  name                                = var.database_name
  username                            = jsondecode(data.aws_secretsmanager_secret_version.database_credentials.secret_string)["username"]
  password                            = jsondecode(data.aws_secretsmanager_secret_version.database_credentials.secret_string)["password"]
  parameter_group_name                = "default.mysql8.0"
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  final_snapshot_identifier           = "tandym-${var.project}-${var.environment}"
  vpc_security_group_ids              = ["${aws_security_group.allow_vpc_traffic.id}"]
  db_subnet_group_name                = aws_db_subnet_group.rds_db_application_subnet.id
  multi_az                            = var.multi_az
  apply_immediately                   = var.apply_immediately
  maintenance_window                  = var.maintainance_window
  backup_window                       = var.backup_window
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  backup_retention_period             = var.backup_retention_period
  performance_insights_enabled        = var.performance_insights_enabled
  monitoring_interval                 = var.monitoring_interval
  max_allocated_storage               = var.max_allocated_storage
  storage_encrypted                   = var.encryption_enabled
  tags = {
    ManagedBy = "${var.maintainer}-terraform"
  }

  lifecycle {
    ignore_changes = [allocated_storage, username,deletion_protection, replicas,password,backup_retention_period,maintenance_window,backup_window,engine_version,instance_class,max_allocated_storage,performance_insights_enabled,monitoring_interval,apply_immediately,multi_az,enabled_cloudwatch_logs_exports,final_snapshot_identifier]
  }
}