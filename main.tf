resource "aws_ecs_cluster" "yh-cluster" {
  name = "yh-cluster"
}

resource "aws_ecs_task_definition" "yh-task" {
  family                   = "yh-task"
  container_definitions    = jsonencode([
    {
      name      = "yh-container"
      image     = "nginx:latest"
      memory    = 512
      cpu       = 256
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
}

resource "aws_ecs_service" yh_service" {
  name            = "yh-service"
  cluster         = aws_ecs_cluster.yh_cluster.id
  task_definition = aws_ecs_task_definition.yh_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-005946c78ffd939e9"]
    security_groups = ["sg-05a8779df838e6451"]
    assign_public_ip = true
  }
}
