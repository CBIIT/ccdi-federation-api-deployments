module "lb_target_group_frontend" {
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/target-group?ref=v3.0.15"

  app                              = var.app
  env                              = terraform.workspace
  program                          = var.program
  health_check_healthy_threshold   = 5
  health_check_path                = "/"
  health_check_protocol            = "HTTP"
  health_check_port                = "traffic-port"
  health_check_matcher             = "200"
  health_check_interval            = 30
  health_check_timeout             = 10
  health_check_unhealthy_threshold = 5
  port                             = 80
  protocol                         = "HTTP"
  resource_name_suffix             = "target-frontend"
  stickiness_type                  = "lb_cookie"
  stickiness_cookie_duration       = 1800
  stickiness_enabled               = true
  target_type                      = "ip"
  vpc_id                           = data.aws_vpc.vpc.id
}

module "lb_target_group_backend" {
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/target-group?ref=v3.0.15"

  app                              = var.app
  env                              = terraform.workspace
  program                          = var.program
  health_check_healthy_threshold   = 5
  health_check_path                = "/ping"
  health_check_protocol            = "HTTP"
  health_check_port                = "traffic-port"
  health_check_matcher             = "200"
  health_check_interval            = 30
  health_check_timeout             = 10
  health_check_unhealthy_threshold = 5
  port                             = 8080
  protocol                         = "HTTP"
  resource_name_suffix             = "target-backend"
  stickiness_type                  = "lb_cookie"
  stickiness_cookie_duration       = 1800
  stickiness_enabled               = true
  target_type                      = "ip"
  vpc_id                           = data.aws_vpc.vpc.id
}
