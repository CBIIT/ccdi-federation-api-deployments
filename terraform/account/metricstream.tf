module "new_relic_metric_pipeline" {
  source = "github.com/CBIIT/datacommons-devops/terraform/modules/firehose-metrics/"

  account_id               = data.aws_caller_identity.current.account_id
  app                      = var.app
  http_endpoint_access_key = var.http_endpoint_access_key
  level                    = terraform.workspace
  new_relic_account_id     = var.new_relic_account_id
  permission_boundary_arn  = local.permission_boundary_arn
  program                  = var.program
  s3_bucket_arn            = module.s3_service_logs.arn
}