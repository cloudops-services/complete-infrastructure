resource "aws_security_group" "backend_security_group" {
  name        = "asg-${var.project}-${var.environment}-fg-backend"
  description = "${var.project}-${var.environment}-ecs backend security group"
  vpc_id      = var.vpc_id

  tags = {
    Environment = "${var.environment}"
    ManagedBy   = "${var.maintainer}-terraform"
  }

  ingress {
    from_port   = var.container_port_backend
    to_port     = var.container_port_backend
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_alb" "backend_alb" {
  name            = "${var.project}-${var.environment}-alb-backend"
  internal        = false
  subnets         = var.public_subnets
  security_groups = [aws_security_group.backend_security_group.id]
}

resource "aws_alb_target_group" "backend_target_group" {
  name        = "${var.project}-${var.environment}-tg-fg-alb-backend"
  protocol    = "HTTP"
  port        = var.container_port_backend
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 10
    interval            = 120
    timeout             = 10
    path                = var.health_check_path
  }

  stickiness {
    type = "lb_cookie"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
}

resource "aws_alb_listener" "backend_https_listener" {
  load_balancer_arn = aws_alb.backend_alb.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.backend_wildcard_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.backend_target_group.arn
  }
}

resource "aws_lb_listener" "backend_http_listener" {
  count             = var.http_redirect ? 1 : 0
  load_balancer_arn = aws_alb.backend_alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener_rule" "backend_host_based_routing" {
  listener_arn = aws_alb_listener.backend_https_listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.backend_target_group.arn
  }

  condition {
    host_header {
      values = ["${var.project}.${var.environment}.${var.app_domain_name}"]
    }
  }
}

resource "aws_service_discovery_private_dns_namespace" "private_namespace" {
  name        = "${var.environment}.local"
  description = "${var.environment} ${var.project} private dns namespace"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "backend_discovery_service" {
  name = var.project

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.private_namespace.id

    dns_records {
      ttl  = 5
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
