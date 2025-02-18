resource "aws_ecs_cluster" "yh_cluster" {  # 이름 수정 (하이픈 제거)
  name = "yh-cluster"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "yh_task" {  # 하이픈 제거
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

resource "aws_ecs_service" "yh_service" {
  name            = "yh-service"
  cluster         = aws_ecs_cluster.yh_cluster.id  # 하이픈 제거한 이름으로 수정
  task_definition = aws_ecs_task_definition.yh_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-005946c78ffd939e9"]
    security_groups = ["sg-06321d9e26e03d2a4"]
    assign_public_ip = true
  }
}

resource "aws_lb" "yh_lb" {
  name               = "yh-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = ["subnet-005946c78ffd939e9"]
}

resource "aws_lb_target_group" "yh_target_group" {
  name     = "yh-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-071cde0c7a3a4a818"
}

resource "aws_lb_listener" "yh_listener" {
  load_balancer_arn = aws_lb.yh_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "NGINX Service is running!"
    }
  }
}
