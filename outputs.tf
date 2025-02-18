output "cluster_name" {
  value = aws_ecs_cluster.yh_cluster.name
}

output "task_definition" {
  value = aws_ecs_task_definition.yh_task.family
}
