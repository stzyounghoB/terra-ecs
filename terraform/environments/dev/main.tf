module "ecs" {
  source        = "../modules/ecs"
  cluster_name  = "my-ecs-cluster"
  desired_count = 2
}
