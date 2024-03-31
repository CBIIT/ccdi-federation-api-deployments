resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.iam_prefix}-${var.program}-${var.app}-${terraform.workspace}-integration-host-profile"
  role = aws_iam_role.jenkins.name
}

resource "aws_iam_role" "jenkins" {
  name                 = "${var.iam_prefix}-${var.program}-${var.app}-${terraform.workspace}-integration-host-role"
  description          = "Role for the integration server profile"
  assume_role_policy   = data.aws_iam_policy_document.integration_server_assume_role.json
  permissions_boundary = local.permission_boundary_arn
}

resource "aws_iam_policy" "jenkins" {
  name        = "${var.iam_prefix}-${var.program}-${var.app}-${terraform.workspace}-integration-host-policy"
  description = "Policy for the integration server profile role"
  policy      = data.aws_iam_policy_document.integration_server_policy.json
}

resource "aws_iam_role_policy_attachment" "jenkins" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins.arn
}

resource "aws_iam_role_policy_attachment" "managed_cloudwatch" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "managed_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
