locals {
  iam_prefix                   = "power-user"
  level                        = terraform.workspace == "stage" || terraform.workspace == "prod" ? "prod" : "nonprod"
  permissions_boundary         = terraform.workspace == "dev" || terraform.workspace == "qa" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PermissionBoundary_PowerUser" : null
  nih_cidrs                    = ["129.43.0.0/16", "137.187.0.0/16", "10.128.0.0/9", "165.112.0.0/16", "156.40.0.0/16", "10.208.0.0/21", "128.231.0.0/16", "130.14.0.0/16", "157.98.0.0/16", "10.133.0.0/16"]
  fargate_security_group_ports = ["443", "3306", "7473", "7474", "7687"]


  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  application_url = terraform.workspace == "prod" ? "federation.ccdi.cancer.gov" : "federation-${terraform.workspace}.ccdi.cancer.gov"

  dynamic_secrets = {
    app = {
      secretKey   = ""
      description = ""
      secretValue = {
        sumo_collector_token_frontend = module.monitoring.sumo_source_urls.frontend[0]
        sumo_collector_token_backend  = module.monitoring.sumo_source_urls.backend[0]
        sumo_collector_token_files    = module.monitoring.sumo_source_urls.files[0]
      }
    }
  }
}