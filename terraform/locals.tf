locals {
  application_url      = terraform.workspace == "prod" ? "${var.project}.${var.program}.cancer.gov" : "${var.project}-${terraform.workspace}.${var.program}.cancer.gov"
  iam_prefix           = "power-user"
  level                = terraform.workspace == "stage" || terraform.workspace == "prod" ? "prod" : "nonprod"
  nih_cidrs            = ["129.43.0.0/16", "137.187.0.0/16", "10.128.0.0/9", "165.112.0.0/16", "156.40.0.0/16", "10.208.0.0/21", "128.231.0.0/16", "130.14.0.0/16", "157.98.0.0/16", "10.133.0.0/16"]
  permissions_boundary = terraform.workspace == "dev" || terraform.workspace == "qa" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PermissionBoundary_PowerUser" : null

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  secrets = jsonencode({
    federation_apis              = var.federation_apis
    new_relic_metrics_api_key    = var.new_relic_metrics_api_key
    new_relic_sidecar_api_key    = var.new_relic_sidecar_api_key
    new_relic_metrics_account_id = var.new_relic_account_id
    sumo_logic_api_key           = var.sumo_logic_api_key
    central_ecr_account_id       = var.central_ecr_account_id
  })
}
