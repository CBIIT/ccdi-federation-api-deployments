resource "aws_cloudwatch_log_group" "ecs_execute_command_log_group" {
  # checkov:skip=CKV_AWS_158: No need to encrypt with KMS CMK
  name              = "${var.program}-${var.app}-${terraform.workspace}-ecs-exec"
  retention_in_days = 90
}