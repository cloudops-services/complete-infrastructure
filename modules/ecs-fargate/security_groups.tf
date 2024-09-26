resource "aws_security_group" "backend-ecs-alb-security-group" {
  name        = "asg-alb-${var.environment}-backend-fg"
  description = "Load balancer HTTP/S ${var.environment} backend ecs security group"
  vpc_id      = var.vpc_id

  tags = {
    Environment = "${var.environment}"
    ManagedBy   = "${var.maintainer}-terraform"
  }

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
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend-ecs-service-security-group" {
  name        = "isg-ecs-service-${var.environment}-backend-fg"
  description = "Backend ECS service security group"
  vpc_id      = var.vpc_id

  tags = {
    Environment = "${var.environment}"
    ManagedBy   = "${var.maintainer}-terraform"
  }

  ingress {
    from_port   = var.container_port_api
    to_port     = var.container_port_api
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
