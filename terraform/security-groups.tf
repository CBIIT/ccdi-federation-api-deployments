resource "aws_security_group_rule" "alb_http_inbound" {
  security_group_id = module.alb.alb_securitygroup_id
  type              = "ingress"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_https_inbound" {
  security_group_id = module.alb.alb_securitygroup_id
  type              = "ingress"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "inbound_fargate" {
  security_group_id        = module.ecs.ecs_security_group_id
  type                     = "ingress"
  from_port                = 3000
  protocol                 = "tcp"
  to_port                  = 3000
  source_security_group_id = module.alb.alb_securitygroup_id
}
