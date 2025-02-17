# main.tf

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_ecs_cluster" "example" {
  name = "my-cluster"
}

resource "aws_ecr_repository" "example" {
  name = "my-repository-ecs"
}

# IAM 역할 생성
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM 역할에 정책 부여 (ECR 액세스 권한 포함)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

# ECS Task Definition
resource "aws_ecs_task_definition" "example" {
  family                = "my-task-definition"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  
  cpu                    = "256"  # 0.25 vCPU
  memory                 = "512"  # 0.5 GB

  execution_role_arn     = aws_iam_role.ecs_task_execution_role.arn  # 실행 역할 추가
  task_role_arn          = aws_iam_role.ecs_task_execution_role.arn  # 선택적으로 태스크 역할도 지정

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
