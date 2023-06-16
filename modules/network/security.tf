### External ALB SG

resource "aws_security_group" "ext_alb_sg" {
  name        = "tf-ecs-alb"
  description = "Enable HTTP/HTTPs ingress"
  vpc_id      = "${aws_vpc.main.id}"
}

resource "aws_security_group_rule" "ext_alb_sg_egress_any_any" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ext_alb_sg.id}"
}

resource "aws_security_group_rule" "ext_alb_sg_ingress_any_http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow incoming HTTP traffic from anywhere"
  security_group_id = "${aws_security_group.ext_alb_sg.id}"
}

resource "aws_security_group_rule" "ext_alb_sg_ingress_any_https" {
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow incoming HTTPS traffic from anywhere"
  security_group_id = "${aws_security_group.ext_alb_sg.id}"
}


### Internal ALB SG

resource "aws_security_group" "int_alb_sg" {
  description = "Enable access from ELB to app"
  vpc_id      = "${aws_vpc.main.id}"
}

resource "aws_security_group_rule" "int_alb_sg_ingress_int-webapp" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  security_group_id        = "${aws_security_group.int_alb_sg.id}"
  source_security_group_id = "${aws_security_group.internal_sg.id}"
}

resource "aws_security_group_rule" "int_alb_sg_ingress_int-webapp" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  security_group_id        = "${aws_security_group.int_alb_sg.id}"
  source_security_group_id = "${aws_security_group.internal_sg.id}"
}






resource "aws_security_group_rule" "monitoring_int_alb_sg_ingress_int-alb_prometheus" {
  type      = "ingress"
  from_port = 9090
  to_port   = 9090
  protocol  = "tcp"

  security_group_id        = "${aws_security_group.monitoring_int_alb_sg.id}"
  source_security_group_id = "${aws_security_group.monitoring_internal_sg.id}"

  description = "Nginx auth container to load balanced prometheus"
}