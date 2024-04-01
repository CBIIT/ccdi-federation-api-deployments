resource "aws_security_group_rule" "alb_http_inbound" {
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  cidr_blocks       = concat(local.allowed_alb_ip_range, var.allowed_ip_blocks)
  security_group_id = module.alb.alb_securitygroup_id
  type              = "ingress"

  depends_on = [
    module.alb
  ]
}

resource "aws_security_group_rule" "alb_https_inbound" {
  security_group_id = module.alb.alb_securitygroup_id
  type              = "ingress"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  cidr_blocks       = concat(local.allowed_alb_ip_range, var.allowed_ip_blocks)

  depends_on = [
    module.alb
  ]
}


resource "aws_security_group_rule" "inbound_fargate" {
  for_each = toset(local.fargate_security_group_ports)

  security_group_id        = module.ecs.ecs_security_group_id
  type                     = "ingress"
  from_port                = each.key
  protocol                 = "tcp"
  to_port                  = each.key
  source_security_group_id = module.alb.alb_securitygroup_id
}


resource "aws_security_group_rule" "app_inbound" {
  for_each = var.microservices

  from_port                = each.value.port
  protocol                 = local.tcp_protocol
  to_port                  = each.value.port
  security_group_id        = module.ecs.app_security_group_id
  source_security_group_id = module.alb.alb_securitygroup_id
  type                     = "ingress"
  depends_on = [
    module.alb
  ]
}
