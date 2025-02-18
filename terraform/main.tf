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

# ECR 리포지토리 생성
resource "aws_ecr_repository" "yh_ecs_repository" {
  name = "yh-ecs-repository"
}

# ECR 리포지토리에 대한 IAM 권한 부여 (EC2가 ECR에 접근할 수 있도록)
resource "aws_iam_role_policy_attachment" "ecs_execution_role_ecr_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "ecs_s3_policy" {
  name = "ecsS3Policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::yh-terra-ecs/application.yml"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "yh_task" {
  family                   = "yh-task"
  container_definitions    = jsonencode([
    {
      name      = "yh-container"
      image     = "123456789012.dkr.ecr.us-west-2.amazonaws.com/yh-spring-boot-repository:latest"
      memory    = 512
      cpu       = 256
      essential = true
      portMappings = [
        {
          containerPort = 8080    # Spring Boot 앱 포트
          hostPort      = 8080    # 호스트 포트
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.yh_rds.endpoint  # RDS 엔드포인트
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_NAME"
          value = aws_db_instance.yh_rds.db_name 
        },
        {
          name  = "DB_USER"
          value = aws_db_instance.yh_rds.username  
        },
        {
          name  = "DB_PASSWORD"
          value = aws_db_instance.yh_rds.password  
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

resource "aws_security_group" "ecs_sg" {
  name_prefix = "ecs-security-group"
  vpc_id      = "vpc-071cde0c7a3a4a818"  # ECS와 동일한 VPC ID

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 모든 IP에서 80 포트 접근 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "yh_lb" {
  name               = "yh-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = ["subnet-005946c78ffd939e9", "subnet-0fefd21b4221bbf5e"]
}

resource "aws_lb_target_group" "yh_target_group" {
  name     = "yh-target-group"
  port     = 8080  # Spring Boot 앱 포트
  protocol = "HTTP"
  vpc_id   = "vpc-071cde0c7a3a4a818"
}

resource "aws_lb_listener" "yh_listener" {
  load_balancer_arn = aws_lb.yh_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.yh_target_group.arn  # ALB Target Group
  }
}

resource "aws_db_instance" "yh_rds" {
  identifier        = "yh-rds-instance"
  engine            = "mysql"  # 또는 다른 DB 엔진을 선택
  engine_version    = "8.0"    # 버전 설정
  instance_class    = "db.t3.micro"  # DB 인스턴스 클래스
  allocated_storage = 20      # 디스크 크기
  username          = "admin" # DB 사용자
  password          = "your-password"  # 비밀번호
  db_name           = "myappdb"  # 생성할 데이터베이스 이름
  publicly_accessible = false  # RDS를 퍼블릭으로 액세스할지 여부

  # VPC와 서브넷 설정
  vpc_security_group_ids = ["sg-06321d9e26e03d2a4"]  # RDS와 연결된 보안 그룹
  db_subnet_group_name   = aws_db_subnet_group.yh_subnet_group.name

  # 백업 및 유지보수 설정
  backup_retention_period = 7  # 백업 기간
  multi_az               = false
}

resource "aws_db_subnet_group" "yh_subnet_group" {
  name       = "yh-db-subnet-group"
  subnet_ids = ["subnet-005946c78ffd939e9", "subnet-0fefd21b4221bbf5e"]  # RDS에 사용할 서브넷 ID
}
