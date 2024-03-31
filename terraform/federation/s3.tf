########################################################################################################################
## S3 Config Bucket ####################################################################################################
########################################################################################################################

module "s3_config_bucket" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/s3?ref=v3.0.15"

  app                      = var.app
  env                      = local.level
  program                  = var.program
  bucket_suffix            = "config"
  force_destroy            = false
  enable_access_logging    = false
  enable_object_expiration = false
  enable_object_versioning = false
}

module "s3_config_bucket_policy" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/s3-bucket-policy/config?ref=v3.0.15"

  s3_bucket_arn = module.s3_config_bucket[0].arn
  s3_bucket_id  = module.s3_config_bucket[0].id
}

########################################################################################################################
## Data/ETL Bucket #####################################################################################################
########################################################################################################################

module "s3_etl_bucket" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/s3?ref=v3.1.33"

  app                      = var.app
  env                      = local.level
  program                  = var.program
  bucket_suffix            = var.etl_bucket_suffix
  force_destroy            = true
  access_logs_enabled      = false
  versioning_enabled       = true
  lifecycle_policy_enabled = false
}

data "aws_s3_bucket" "s3_etl_bucket" {
  count  = terraform.workspace == "dev" || terraform.workspace == "stage" ? 0 : 1
  bucket = "${var.program}-${local.level}-${var.app}-${var.etl_bucket_suffix}"
}

########################################################################################################################
## Opensearch Snapshot Bucket #####################################################################################################
########################################################################################################################


#S3 bucket for storing OpenSearch Snapshots
module "s3_opensearch_snapshot" {
  count  = terraform.workspace == "stage" ? 1 : 0
  source = "git::https://github.com/CBIIT/datacommons-devops.git//terraform/modules/s3?ref=main"
  bucket_name = local.s3_snapshot_bucket_name
  resource_prefix = "${var.program}-${terraform.workspace}-${var.app}"
  env = terraform.workspace
  s3_force_destroy = true
  days_for_archive_tiering = 125
  days_for_deep_archive_tiering = 180
  s3_enable_access_logging = false
  s3_access_log_bucket_id = ""
  tags = {
      "Name" = "${var.program}-${var.app}-${terraform.workspace}-opensearch-snapshot-bucket"
  }
}