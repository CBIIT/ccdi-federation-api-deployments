module "alb" {
  source = "git::https://github.com/CBIIT/datacommons-devops.git//terraform/modules/loadbalancer?ref=v1.16"

  alb_certificate_arn = data.aws_acm_certificate.domain.arn
  alb_internal        = terraform.workspace == "dev" ? false : true
  alb_subnet_ids      = terraform.workspace == "dev" ? data.aws_subnets.webapp.ids : data.aws_subnets.public[0].ids
  env                 = terraform.workspace
  program             = var.program
  resource_prefix     = "${var.program}-${terraform.workspace}-${var.project}"
  stack_name          = var.project
  vpc_id              = data.aws_vpc.vpc.id

  tags = {
    EnvironmentTier  = upper(terraform.workspace)
    ResourceFunction = "Load Balancing"
  }
}

module "ecs" {
  source = "git::https://github.com/CBIIT/datacommons-devops.git//terraform/modules/ecs?ref=v1.16"

  alb_https_listener_arn = module.alb.alb_https_listener_arn
  application_url        = local.application_url
  central_ecr_account_id = var.central_ecr_account_id
  ecs_subnet_ids         = data.aws_subnets.webapp.ids
  env                    = terraform.workspace
  microservices          = var.microservices
  resource_prefix        = "${var.program}-${terraform.workspace}-${var.project}"
  stack_name             = var.project
  vpc_id                 = data.aws_vpc.vpc.id

  tags = {
    EnvironmentTier  = upper(terraform.workspace)
    ResourceFunction = "API Service"
  }
}

# module "new_relic_metric_pipeline" {
#   count  = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0
#   source = "git::https://github.com/CBIIT/datacommons-devops.git//terraform/modules/firehose-metrics?ref=v1.16"

#   account_id               = data.aws_caller_identity.current.account_id
#   app                      = var.project
#   http_endpoint_access_key = var.new_relic_api_key
#   level                    = var.account_level
#   new_relic_account_id     = var.new_relic_account_id
#   permission_boundary_arn  = local.permissions_boundary
#   program                  = var.program
#   s3_bucket_arn            = aws_s3_bucket.kinesis[0].arn
#   resource_prefix          = "${var.program}-${local.account_level}-${var.project}"
# }

# # Monitoring
# module "monitoring" {
#   source = "git::https://github.com/CBIIT/datacommons-devops.git//terraform/modules/monitoring?ref=v1.9"

#   app                  = var.project
#   sumologic_access_id  = var.sumologic_access_id
#   sumologic_access_key = var.sumologic_access_key
#   microservices        = var.microservices
#   service              = var.service
#   program              = var.program
#   newrelic_account_id  = var.newrelic_account_id
#   newrelic_api_key     = var.newrelic_api_key
#   resource_prefix      = "${var.program}-${terraform.workspace}-${var.project}"

#   tags = {
#     EnvironmentTier  = upper(terraform.workspace)
#     ResourceFunction = "Monitoring"
#   }
# }