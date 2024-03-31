module "lb_listener_rule_frontend" {
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/alb-listener-rule?ref=v3.1.1"

  condition_host_header  = [local.url_full]
  condition_path_pattern = ["/*"]
  listener_arn           = module.lb.https_listener_arn
  priority               = 5
  target_group_arn       = module.lb_target_group_frontend.arn
}

module "lb_listener_rule_backend" {
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/alb-listener-rule?ref=v3.1.1"

  condition_host_header  = [local.url_full]
  condition_path_pattern = ["/v1/graphql/*"]
  listener_arn           = module.lb.https_listener_arn
  priority               = 4
  target_group_arn       = module.lb_target_group_backend.arn
}
