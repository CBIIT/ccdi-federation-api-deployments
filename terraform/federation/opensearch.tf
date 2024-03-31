module "opensearch" {
  source = "git::https://github.com/CBIIT/ccdi-devops.git//terraform/constructs/opensearch?ref=v1.0.0"

  # OpenSearch Variables
  app                  = var.app
  create_domain_policy = true
  engine_version       = "1.3"
  hot_node_count       = 2
  hot_node_type        = "m6g.large.search"
  master_node_count    = null
  master_node_enabled  = false
  master_node_type     = null
  multi_az             = true
  program              = var.program
  subnet_ids           = data.aws_subnets.database.ids
  tier                 = terraform.workspace
  vpc_id               = data.aws_vpc.vpc.id
  ebs_volume_size      = 20

  # Security Group Variables
  allow_nih_access = true

}