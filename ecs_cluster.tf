resource "aws_ecs_cluster" "default" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  depends_on = [aws_cloudwatch_log_group.container_insights_performance]
}

resource "aws_cloudwatch_log_group" "container_insights_performance" {
  name              = "/aws/ecs/containerinsights/${local.name}/performance"
  retention_in_days = 1
}