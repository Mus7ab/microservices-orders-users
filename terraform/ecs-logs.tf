resource "aws_cloudwatch_log_group" "orders" {
  name              = "/ecs/${var.project_name}-orders"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "users" {
  name              = "/ecs/${var.project_name}-users"
  retention_in_days = 7
}
