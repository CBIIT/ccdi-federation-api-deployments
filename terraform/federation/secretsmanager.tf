module "secrets-manager" {
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/modules/secrets-manager?ref=v1.0.0"

  secrets = merge(
    {
      "opensearch_host" = "${module.opensearch.opensearch_endpoint}"
    },
  var.secrets)
  app     = var.app
  program = var.program
  tier    = terraform.workspace
}
