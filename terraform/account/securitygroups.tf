resource "aws_security_group" "jenkins" {
  name        = "${var.program}-${var.app}-${terraform.workspace}-jenkins"
  description = "The security group for jenkins instances"
  vpc_id      = local.vpc_id

  tags = {
    "Name" = "${var.program}-${var.app}-${terraform.workspace}-jenkins"
  }
}

resource "aws_security_group_rule" "nih_ingress" {
  security_group_id = aws_security_group.jenkins.id
  type              = "ingress"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  cidr_blocks       = local.nih_cidrs
}

resource "aws_security_group_rule" "all_egress" {
  security_group_id = aws_security_group.jenkins.id
  type              = "egress"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  cidr_blocks       = local.public_service_endpoints
  ipv6_cidr_blocks  = local.ipv6_all
}