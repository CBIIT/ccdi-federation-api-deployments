locals {
  alb_internal            = terraform.workspace == "prod" || terraform.workspace == "stage" ? false : true
  alb_inbound_cidr        = terraform.workspace == "prod" || terraform.workspace == "stage" ? ["0.0.0.0/0"] : local.nih_cidrs
  level                   = terraform.workspace == "prod" || terraform.workspace == "stage" ? "prod" : "nonprod"
  nih_cidrs               = ["129.43.0.0/16", "137.187.0.0/16", "10.128.0.0/9", "165.112.0.0/16", "156.40.0.0/16", "10.208.0.0/21", "128.231.0.0/16", "130.14.0.0/16", "157.98.0.0/16", "10.133.0.0/16"]
  permission_boundary_arn = terraform.workspace == "dev" || terraform.workspace == "qa" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PermissionBoundary_PowerUser" : null
  service_log_bucket      = "${var.program}-${var.app}-${local.level}-central-log-destination-bucket"
  s3_snapshot_bucket_name = "opensearch-snapshot-bucket"
  url_full                = terraform.workspace == "prod" ? "studycatalog.cancer.gov" : "studycatalog-${terraform.workspace}.cancer.gov"
}
