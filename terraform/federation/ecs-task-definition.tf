resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.program}-${var.app}-${terraform.workspace}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "019211168375.dkr.ecr.us-east-1.amazonaws.com/cbiit-base-docker-images:nginx-1.20.7"
      essential = true
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.program}-${var.app}-${terraform.workspace}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "019211168375.dkr.ecr.us-east-1.amazonaws.com/cbiit-base-docker-images:cbiit-alpine-linux"
      essential = true

      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}