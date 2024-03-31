# resource "aws_iam_policy" "ecs_policy" {
#   name   = local.ecs_policy_name
#   policy = data.aws_iam_policy_document.ecs_policy_doc.json
# }

# resource "aws_iam_policy_attachment" "ecs_policy_attachment" {
#   name       = local.ecs_policy_attachment_name
#   policy_arn = aws_iam_policy.ecs_policy.arn
#   roles      = [module.ecs.task_role_name]
# }



resource "aws_iam_role" "ecs_task_execution_role" {
  name                 = "power-user-${var.program}-${var.app}-${terraform.workspace}-ecs-task-execution-role"
  assume_role_policy   = data.aws_iam_policy_document.ecs_trust_policy.json
  permissions_boundary = local.permission_boundary_arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_role_policy.arn
}

resource "aws_iam_policy" "ecs_task_execution_role_policy" {
  name   = "power-user-${var.program}-${var.app}-${terraform.workspace}-ecs-task-execution-role-policy"
  policy = data.aws_iam_policy_document.ecs_task_execution_role_policy_doc.json
}

resource "aws_iam_role" "ecs_task_role" {
  name                 = "power-user-${var.program}-${var.app}-${terraform.workspace}-ecs-task-role"
  assume_role_policy   = data.aws_iam_policy_document.ecs_trust_policy.json
  permissions_boundary = local.permission_boundary_arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_exec_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role_exec_policy.arn
}

resource "aws_iam_policy" "ecs_task_role_exec_policy" {
  name   = "power-user-${var.program}-${var.app}-${terraform.workspace}-ecs-task-role-exec-policy"
  policy = data.aws_iam_policy_document.ecs_task_role_exec_policy_doc.json
}


resource "aws_iam_instance_profile" "neo4j" {
  name = "power-user-${var.program}-${var.app}-${terraform.workspace}-neo4j-host-profile"
  role = aws_iam_role.neo4j.name
}

resource "aws_iam_role" "neo4j" {
  name                 = "power-user-${var.program}-${var.app}-${terraform.workspace}-neo4j-host-role"
  description          = "Role for the Neo4j server profile"
  assume_role_policy   = data.aws_iam_policy_document.neo4j_server_assume_role.json
  permissions_boundary = local.permission_boundary_arn
}

resource "aws_iam_policy" "neo4j" {
  name        = "power-user-${var.program}-${var.app}-${terraform.workspace}-neo4j-host-policy"
  description = "Policy for the Neo4j server profile role"
  policy      = data.aws_iam_policy_document.neo4j_server_policy.json
}

resource "aws_iam_role_policy_attachment" "neo4j" {
  role       = aws_iam_role.neo4j.name
  policy_arn = aws_iam_policy.neo4j.arn
}

resource "aws_iam_role_policy_attachment" "neo4j_managed_cloudwatch" {
  role       = aws_iam_role.neo4j.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "neo4j_managed_ecr" {
  role       = aws_iam_role.neo4j.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
