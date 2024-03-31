resource "aws_security_group" "ecs" {
  # checkov:skip=CKV2_AWS_5: No need to add to another resource
  name        = "${var.program}-${var.app}-${terraform.workspace}-ecs"
  description = "The security group controlling access to Fargate/ECS resources"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    "Name" = "${var.program}-${var.app}-${terraform.workspace}-ecs"
  }
}

resource "aws_security_group" "neo4j" {
  name        = "${var.program}-${var.app}-${terraform.workspace}-neo4j"
  description = "The security group controlling access to the ${terraform.workspace} Neo4j host"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    "Name" = "${var.program}-${var.app}-${terraform.workspace}-neo4j"
  }
}


