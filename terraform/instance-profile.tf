resource "aws_iam_instance_profile" "jenkins" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  name = "${local.iam_prefix}-${var.program}-${local.account_level}-${var.project}-jenkins"
  role = aws_iam_role.jenkins[0].name
}

resource "aws_iam_role" "jenkins" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  name                 = "${local.iam_prefix}-${var.program}-${local.account_level}-${var.project}-jenkins"
  assume_role_policy   = data.aws_iam_policy_document.jenkins_trust[0].json
  permissions_boundary = local.permissions_boundary
}

resource "aws_iam_policy" "jenkins" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  name        = "${local.iam_prefix}-${var.program}-${local.account_level}-${var.project}-jenkins"
  description = "IAM Policy for the integration server host in this account"
  policy      = data.aws_iam_policy_document.jenkins[0].json
}

resource "aws_iam_role_policy_attachment" "jenkins" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  role       = aws_iam_role.jenkins[0].name
  policy_arn = aws_iam_policy.jenkins[0].arn
}

resource "aws_iam_role_policy_attachment" "managed_ecr" {
  for_each = terraform.workspace == "dev" || terraform.workspace == "stage" ? toset(local.managed_policy_arns) : toset([])

  role       = aws_iam_role.jenkins[0].name
  policy_arn = each.key
}
