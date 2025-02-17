# main.tf

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_ecs_cluster" "example" {
  name = "my-cluster"
}

resource "aws_ecr_repository" "example" {
  name = "my-repository"
}

resource "aws_ecs_task_definition" "example" {
  family                = "my-task-definition"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu                    = "256"  # 추가
  memory                 = "512"  # 추가

  container_definitions = <<DEFINITION
  [
    {
      "name": "my-container",
      "image": "${aws_ecr_repository.example.repository_url}:latest",
      "memory": 512,
      "cpu": 256,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_ecs_service" "example" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-xxxxxx"]
    security_groups = ["sg-xxxxxx"]
  }
}
