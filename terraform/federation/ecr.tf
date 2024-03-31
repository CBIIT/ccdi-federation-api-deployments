module "ecr-frontend" {
  count  = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/modules/ecr?ref=v1.0.0"

  repo_type            = "frontend"
  program              = var.program
  app                  = var.app
  account_level        = local.level
  image_tag_mutability = "MUTABLE"
}

module "ecr-backend" {
  count  = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/modules/ecr?ref=v1.0.0"

  repo_type            = "backend"
  program              = var.program
  app                  = var.app
  account_level        = local.level
  image_tag_mutability = "MUTABLE"
}
