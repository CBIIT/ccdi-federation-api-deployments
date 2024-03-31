# This bucket stores AWS Service logs, such as ALB access logs, cloudtrail logs, etc.
module "s3_service_logs" {
  source = "github.com/CBIIT/ccdi-devops/terraform/constructs/s3/s3-service-logs?ref=v1.0.0"

  account_id        = data.aws_caller_identity.current.account_id
  program           = var.program
  app               = var.app
  level             = terraform.workspace
  target_log_bucket = module.s3_bucket_access_logs.id
}

# This bucket stores S3 Access Logs
module "s3_bucket_access_logs" {
  source = "github.com/CBIIT/ccdi-devops/terraform/constructs/s3/s3-access-logs?ref=v1.0.0"

  program = var.program
  app     = var.app
  level   = terraform.workspace
}
