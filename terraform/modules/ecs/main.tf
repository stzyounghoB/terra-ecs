resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::123456789012:role/ecsTaskRole"
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "my-container"
      image     = var.container_image
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "my_service" {
  name            = "my-app-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.my_task.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "my-container"
    container_port   = var.container_port
  }
}
