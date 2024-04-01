resource "aws_iam_instance_profile" "integration_server" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  name = "${local.iam_prefix}-${var.program}-${local.level}-${var.project}-jenkins"
  role = aws_iam_role.integration_server[0].name
}

resource "aws_iam_role" "integration_server" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  name                 = "${local.iam_prefix}-${var.program}-${local.level}-${var.project}-jenkins"
  assume_role_policy   = data.aws_iam_policy_document.jenkins_trust[0].json
  permissions_boundary = local.permissions_boundary
}

resource "aws_iam_policy" "integration_server" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  name        = "${local.iam_prefix}-${var.program}-${local.level}-${var.project}-jenkins"
  description = "IAM Policy for the integration server host in this account"
  policy      = data.aws_iam_policy_document.jenkins[0].json
}

resource "aws_iam_role_policy_attachment" "integration_server" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  role       = aws_iam_role.integration_server[0].name
  policy_arn = aws_iam_policy.integration_server[0].arn
}

resource "aws_iam_role_policy_attachment" "managed_ecr" {
  for_each = var.create_instance_profile ? toset(local.managed_policy_arns) : toset([])

  role       = aws_iam_role.integration_server[0].name
  policy_arn = each.key
}
