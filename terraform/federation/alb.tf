# new ALB using new module version
module "lb" {
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/alb?ref=v3.1.1"

  app                        = var.app
  certificate_arn            = data.aws_acm_certificate.domain.arn
  create_http_listener       = true
  create_https_listener      = true
  create_security_group      = true
  vpc_id                     = data.aws_vpc.vpc.id
  env                        = terraform.workspace
  http_port                  = 80
  http_protocol              = "HTTP"
  https_port                 = 443
  https_protocol             = "HTTPS"
  internal                   = terraform.workspace == "dev" || terraform.workspace == "qa" ? true : false
  desync_mitigation_mode     = "monitor"
  drop_invalid_header_fields = true
  enable_deletion_protection = true
  enable_http2               = true
  enable_waf_fail_open       = false
  idle_timeout               = 60
  preserve_host_header       = true
  program                    = var.program
  ssl_policy                 = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  subnets                    = data.aws_subnets.public.ids
}