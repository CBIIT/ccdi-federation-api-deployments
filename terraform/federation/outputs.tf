output "vpc_id" {
  value = data.aws_vpc.vpc.id
}

output "neo4j_password" {
  value     = module.secrets-manager.neo4j_password
  sensitive = true
}