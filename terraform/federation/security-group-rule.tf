#########################################
## ALB Security Group Rules #############
#########################################

resource "aws_security_group_rule" "lb_outbound_app_frontend" {
  security_group_id        = module.lb.security_group_id
  description              = "Allow outbound traffic from the ${terraform.workspace} ALB to ecs frontend services"
  type                     = "egress"
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
  source_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "lb_outbound_app_backend" {
  security_group_id        = module.lb.security_group_id
  description              = "Allow outbound traffic from the ${terraform.workspace} ALB to app backend"
  type                     = "egress"
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
  source_security_group_id = aws_security_group.ecs.id
}


#########################################
## Container Security Group Rules #######
#########################################

resource "aws_security_group_rule" "ecs_frontend_inbound_alb" {
  security_group_id        = aws_security_group.ecs.id
  description              = "Allow inbound traffic originating from the ${terraform.workspace} ALB for frontend services"
  type                     = "ingress"
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
  source_security_group_id = module.lb.security_group_id
  #source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "ecs_backend_inbound_alb" {
  security_group_id        = aws_security_group.ecs.id
  description              = "Allow inbound traffic originating from the ALB for ${terraform.workspace} backend services"
  type                     = "ingress"
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
  #source_security_group_id = aws_security_group.alb.id
  source_security_group_id = module.lb.security_group_id
}

resource "aws_security_group_rule" "ecs_inbound_jenkins" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow inbound traffic originating from the ${local.level}-account Jenkins host to the ${terraform.workspace} ecs services"
  type              = "ingress"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  cidr_blocks       = var.jenkins_cidr
}

resource "aws_security_group_rule" "ecs_outbound_public_service_endpoints" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow outbound access to AWS public service endpoints from the ${terraform.workspace} ECS services"
  type              = "egress"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

#########################################
## OpenSearch Security Group Rules ######
#########################################

resource "aws_security_group_rule" "opensearch_inbound_ecs" {
  security_group_id        = module.opensearch.securitygroup_id
  description              = "Allow inbound traffic originating from ${terraform.workspace} ECS services"
  type                     = "ingress"
  from_port                = 443
  protocol                 = "tcp"
  to_port                  = 443
  source_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "opensearch_inbound_jenkins" {
  security_group_id = module.opensearch.securitygroup_id
  description       = "Allow inbound traffic originating from the Jenkins host to the ${terraform.workspace} cluster"
  type              = "ingress"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  cidr_blocks       = var.jenkins_cidr
}


### neo4j ###

resource "aws_security_group_rule" "neo4j_inbound_nih" {
  security_group_id = aws_security_group.neo4j.id
  description       = "Allow ${terraform.workspace} neo4j inbound traffic originating from the NIH network"
  type              = "ingress"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  cidr_blocks       = local.nih_cidrs
}

resource "aws_security_group_rule" "neo4j_outbound_public_service_endpoints" {
  security_group_id = aws_security_group.neo4j.id
  description       = "Allow ${terraform.workspace} neo4j outbound access to AWS public service endpoints"
  type              = "egress"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}