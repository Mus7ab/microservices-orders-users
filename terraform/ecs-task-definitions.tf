resource "aws_ecs_task_definition" "orders" {
  family                   = "${var.project_name}-orders"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                       = "256"
  memory                    = "512"
  execution_role_arn        = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "orders"
      image     = "342677169816.dkr.ecr.ap-south-2.amazonaws.com/orders-service:v1"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orders.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "orders"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-orders-task"
  }
}
resource "aws_ecs_task_definition" "users" {

 family                   = "${var.project_name}-users"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                       = "256"
  memory                    = "512"
  execution_role_arn        = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "users"
      image     = "342677169816.dkr.ecr.ap-south-2.amazonaws.com/users-service:v1"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.users.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "users"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-users-task"
  }
 }
