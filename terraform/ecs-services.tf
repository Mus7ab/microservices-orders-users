resource "aws_ecs_service" "orders" {
  name            = "${var.project_name}-orders-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.orders.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.orders.arn
    container_name    = "orders"
    container_port    = 3000
  }

  depends_on = [aws_lb_listener_rule.orders]

  tags = {
    Name = "${var.project_name}-orders-service"
  }
}

resource "aws_ecs_service" "users" {
  name            = "${var.project_name}-users-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.users.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.users.arn
    container_name    = "users"
    container_port    = 3000
  }

  depends_on = [aws_lb_listener_rule.users]

  tags = {
    Name = "${var.project_name}-users-service"
  }
}
