resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-security-group"
  description = "${var.name} Load balancer security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}"
  }
}


resource "aws_alb" "alb" {
  name            = "${var.name}-alb"
  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = var.public_subnets
  tags = {
    Name = "${var.name}"
  }
}

resource "random_string" "target_group" {
  length = 4
  special = false
}


resource "aws_alb_target_group" "group" {
  name     = "${var.name}-${random_string.target_group.result}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  deregistration_delay = 60
  target_type = "ip"
  # Alter the destination of the health check to be the login page.
  # Codes up to 302 have been included to handle http -> https redirect in the front end
  health_check {
    path = "/_health"
    port = 80
    interval = 40
    timeout = 30
    healthy_threshold = 3
    unhealthy_threshold = 3
    protocol = "HTTP"
    matcher = "200-302"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      host        = "${var.host_destination}.${var.route53_hosted_zone_name}"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  # default_action {
  #   type             = "forward"
  #   target_group_arn = aws_alb_target_group.group.arn
  # }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.group.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "record" {
  name    = "${var.host_destination}.${var.route53_hosted_zone_name}"
  zone_id = var.zone_id
  allow_overwrite = true
  type    = "A"
  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}



output "alb_target_group" {
  value = aws_alb_target_group.group.arn
}
