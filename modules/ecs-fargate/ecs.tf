data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "backend_wildcard_certificate" {
  domain   = var.environment != "production" ? "*.${var.environment}.${var.app_domain_name}" : "*.${var.app_domain_name}"
  statuses = ["ISSUED"]
  types    = ["AMAZON_ISSUED"]
}

data "aws_route53_zone" "default_app_zone" {
  name = var.app_domain_name
}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  backend_secrets = concat([
    for secret_name in var.backend_secrets : {
      "name"       : upper(secret_name),
      "valueFrom" : "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:/${var.environment}/${var.project}/${lower(secret_name)}"
    }
  ], [
    for secret_name in var.secrets_global : {
      "name"       : upper(secret_name),
      "valueFrom" : "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:/global/${lower(secret_name)}"
    }
  ], [
    for secret_name in var.environment_secrets : {
      "name"       : upper(secret_name),
      "valueFrom" : "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:/${var.environment}/${lower(secret_name)}"
    }
  ])
}

resource "aws_iam_role" "backend_ecs_instance_role" {
  name               = "${var.project}-${var.environment}-ecs-instance-fg-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume_role_policy.json
}

resource "aws_iam_instance_profile" "backend_ecs_instance_profile" {
  name = "${var.project}-${var.environment}-ecs-instance-fg-profile"
  path = "/"
  role = aws_iam_role.backend_ecs_instance_role.name
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.backend_ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "aws_iam_role_policy_secret_manager" {
  name   = "policy-${var.project}-${var.environment}-secret-fg-manager"
  role   = aws_iam_role.backend_ecs_instance_role.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "secretsmanager:GetSecretValue"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:/${var.environment}/${var.project}/*",
          "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:/${var.environment}/*",
          "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:/global/*"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "aws_iam_role_policy_logs" {
  name   = "policy-${var.project}-${var.environment}-fg-logs"
  role   = aws_iam_role.backend_ecs_instance_role.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
          "logs:CreateLogGroup"
        ],
        "Effect": "Allow",
        "Resource": [
          "*"
        ]
      }
    ]
  }
  EOF
}

resource "aws_ecs_cluster" "backend_cluster" {
  name = var.environment
}

resource "aws_ecs_service" "backend_service" {
  name                   = "${var.project}-${var.environment}-service"
  cluster                = aws_ecs_cluster.backend_cluster.id
  task_definition        = aws_ecs_task_definition.application-env.arn
  desired_count          = var.desired_count_backend
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.backend-ecs-service-security-group.id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.backend_target_group.arn
    container_name   = "${var.project}-${var.environment}"
    container_port   = var.container_port_backend
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  service_registries {
    registry_arn = aws_service_discovery_service.backend_discovery_service.arn
  }
}
