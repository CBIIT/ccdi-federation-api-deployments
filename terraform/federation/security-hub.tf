module "securityhub" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/aws/modules/security-hub"

  manager_account_id = var.manager_account_id
}
