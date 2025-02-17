aws_region          = "us-west-2"
ecs_cluster_name    = "dev-ecs-cluster"
alb_target_group_name = "dev-alb-target-group"
subnet_ids          = ["subnet-12345", "subnet-67890"]
security_group_ids  = ["sg-12345"]
container_image     = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:dev-latest"
desired_count       = 1
container_port      = 80
