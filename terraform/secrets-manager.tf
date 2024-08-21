resource "aws_secretsmanager_secret" "secret" {
  name        = "${var.program}-${terraform.workspace}-${var.project}-secrets"
  description = "Secrets for ${var.program}-${terraform.workspace}-${var.project}"
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode(local.secrets)

  lifecycle {
    ignore_changes = [ secret_string ]
  }
}
