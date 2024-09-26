# -------- NLB BASTION HOST --------

# * nlb security group *
resource "aws_security_group" "nlb_main_security_group" {
  name        = "${var.project}-${var.environment}-nlb-sg"
  description = "${var.project}-${var.environment}-nlb security group"
  vpc_id      = var.vpc_id

  tags = {
    Environment = "${var.environment}"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# * nlb resource *
resource "aws_lb" "networking-env-nlb" {
  name            = "bastion-${var.environment}-nlb"
  internal        = false
  load_balancer_type = "network"
  enable_deletion_protection = false
  subnets         = var.public_subnets
  security_groups = [aws_security_group.nlb_main_security_group.id]
  tags = {
    Environment = "${var.environment}"
  }
}

# * nlb target group *
resource "aws_lb_target_group" "networking_env_target_group_nlb" {
  name        = "${var.project}-${var.environment}-tg-nlb"
  protocol    = "TCP"
  port        = "22"
  vpc_id      = var.vpc_id

  health_check {
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3 
    interval            = 10
  }
}

# * aws_lb_target_group_attachment * 
resource "aws_lb_target_group_attachment" "nlb_attachment" {
  target_group_arn = aws_lb_target_group.networking_env_target_group_nlb.arn
  target_id        = aws_instance.bastion-instance.id
  depends_on       = [aws_lb_target_group.networking_env_target_group_nlb]
}

# * listener nlb *
resource "aws_lb_listener" "bastion_host" {
  load_balancer_arn = aws_lb.networking-env-nlb.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.networking_env_target_group_nlb.arn
  }
}

# * nlb DNS record *
resource "aws_route53_record" "secure_bastion" {
  zone_id          = var.environment != "production" ? "Z06239213LRMVY1UUCD5N" : "Z0704072159QO7ED5QR3N"
  name             = var.environment != "production" ? "securebastion.${var.environment}.poweredbytandym.com" : "securebastion.bytandym.com"
  type    = "A"

  alias {
    name                   = aws_lb.networking-env-nlb.dns_name
    zone_id                = aws_lb.networking-env-nlb.zone_id
    evaluate_target_health = true
  }
}