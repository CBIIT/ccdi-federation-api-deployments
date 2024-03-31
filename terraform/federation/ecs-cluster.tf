resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.program}-${var.app}-${terraform.workspace}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      # kms_key_id = aws_kms_key.ecs_exec.key_id
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_execute_command_log_group.name
        cloud_watch_encryption_enabled = false
      }
    }
  }
}