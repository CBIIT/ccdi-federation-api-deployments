resource "aws_ecs_service" "ecs_service_frontend" {
  name                               = "${var.program}-${var.app}-${terraform.workspace}-frontend"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.frontend.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  enable_execute_command             = true

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = data.aws_subnets.webapp.ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.lb_target_group_frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource "aws_ecs_service" "ecs_service_backend" {
  name                               = "${var.program}-${var.app}-${terraform.workspace}-backend"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.backend.arn
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  enable_execute_command             = true

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = data.aws_subnets.webapp.ids
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = module.lb_target_group_backend.arn
    container_name   = "backend"
    container_port   = 8080
  }
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
