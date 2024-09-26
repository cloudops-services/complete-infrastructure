locals {
  environment = [for variable_name, variable_value in var.backend_variables : { name = variable_name, value = variable_value }]

  secrets = concat([
    for secret_name in var.backend_secrets :
    {
      "name"       : upper(secret_name),
      "valueFrom"  : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:/${var.environment}/${var.project}/${lower(secret_name)}"
    }
  ], [
    for secret_name in var.secrets_global :
    {
      "name"       : upper(secret_name),
      "valueFrom"  : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:/global/${lower(secret_name)}"
    }
  ])
}

data "template_file" "container-definitions-application-env" {
  template = file("${path.module}/tasks/default-app.json.tpl")
  vars = {
    region                = var.region
    environment           = var.environment
    environment_variables = jsonencode(local.environment)
    secrets               = jsonencode(local.secrets)
    image                 = "${var.api_image}"
    project               = "${var.project}"
    container_port        = "${var.container_port_api}"
    cpu                   = "${var.api_task_cpu}"
    memory                = "${var.api_task_ram}"
  }
}

data "aws_iam_policy_document" "ecs_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "application-env-ecs-task-role" {
  name               = "${var.project}-${var.environment}-ecs-task-fg-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_ecs_task_definition" "application-env" {
  family                   = "${var.project}-${var.environment}-fargate"
  execution_role_arn       = aws_iam_role.application-env-ecs-task-role.arn
  container_definitions    = data.template_file.container-definitions-application-env.rendered
  task_role_arn            = aws_iam_role.application-env-ecs-task-role.arn
  network_mode             = "awsvpc"
  cpu                      = var.api_task_cpu
  memory                   = var.api_task_ram
  requires_compatibilities = ["FARGATE"]

  volume {
    name = "tmp-volume"
  }
  volume {
    name = "yarn-global-cache-volume"
  }
  volume {
    name = "yarnrc-dir-volume"
  }
  volume {
    name = "ssm-var-lib"
  }
  volume {
    name = "ssm-var-log"
  }
  volume {
    name = "ssm-etc"
  }
}
