locals {
  level                           = terraform.workspace == "stage" || terraform.workspace == "prod" ? "prod" : "nonprod"
  integration_server_profile_name = "${var.iam_prefix}-integration-server-profile"
  permissions_boundary            = terraform.workspace == "dev" || terraform.workspace == "qa" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PermissionBoundary_PowerUser" : null
  nih_cidrs    = ["129.43.0.0/16", "137.187.0.0/16", "10.128.0.0/9", "165.112.0.0/16", "156.40.0.0/16", "10.208.0.0/21", "128.231.0.0/16", "130.14.0.0/16", "157.98.0.0/16", "10.133.0.0/16"]
  
  fargate_security_group_ports = ["443", "3306", "7473", "7474", "7687"]
  
  
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  ]



  # ECS
  application_url = terraform.workspace == "prod" ? "${var.application_subdomain}.${var.domain_name}" : "${var.application_subdomain}-${terraform.workspace}.${var.domain_name}"


  # Secrets
  dynamic_secrets = {
    app = {
      secretKey   = ""
      description = ""
      secretValue = {
        es_host                       = var.create_opensearch_cluster ? module.opensearch[0].opensearch_endpoint : ""
        sumo_collector_token_frontend = module.monitoring.sumo_source_urls.frontend[0]
        sumo_collector_token_backend  = module.monitoring.sumo_source_urls.backend[0]
        sumo_collector_token_files    = module.monitoring.sumo_source_urls.files[0]
        rds_host                      = var.create_rds_mysql ? module.rds_mysql[0].endpoint : ""
        rds_username                  = var.create_rds_mysql ? var.rds_username : ""
        rds_password                  = var.create_rds_mysql ? nonsensitive(random_password.rds_password[0].result) : ""
      }
    }
  }
}