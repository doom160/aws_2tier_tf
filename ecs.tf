resource "aws_ecr_repository" "node_app_registry" {
  name                 = "node_app"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${terraform.workspace}_ecs_cluster"
  tags = {
    env= terraform.workspace
  }
}

resource "aws_ecs_task_definition" "node_app_task_definition" {
  family                = "node_app_task_definition"
  container_definitions = file("tasks-definition/container.json")
  requires_compatibilities = ["EC2","FARGATE"]
  execution_role_arn = aws_iam_role.ecs_iam_role.arn
  task_role_arn = aws_iam_role.ecs_iam_role.arn
  cpu = 256
  memory = 512
  network_mode = "awsvpc"
}

resource "aws_lb_target_group" "node_app_target_group" {
  name     = "node-app-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    path = "/"
    healthy_threshold = 5
  }
}

resource "aws_lb" "node_app_lb" {
  name               = "node-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.allow_all.id ]
  subnets            = aws_subnet.ecs_public_subnet.*.id

  tags = {
    env= terraform.workspace
    app= "node_app"
  }
}

resource "aws_lb_listener" "node_app_lb_listener" {
  load_balancer_arn = aws_lb.node_app_lb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node_app_target_group.arn
  }
}

resource "aws_ecs_service" "node_app_service" {
  name            = "node_app_service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.node_app_task_definition.arn
  desired_count   = 1
  depends_on      = [aws_lb.node_app_lb, aws_lb_target_group.node_app_target_group]
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.node_app_target_group.arn
    container_name   = "app"
    container_port   = 3000
  }
  network_configuration {
    subnets = aws_subnet.ecs_private_subnet.*.id
    security_groups = [ aws_security_group.internal.id ]
    assign_public_ip = true
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/${terraform.workspace}_ecs_cluster/node_app_service"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on      = [aws_ecs_service.node_app_service]
}


resource "aws_appautoscaling_policy" "node_app_memory_policy" {
  name               = "node-app-memory-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
  }
}

resource "aws_appautoscaling_policy" "node_app_cpu_policy" {
  name = "node-app-cpu-policy"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}
