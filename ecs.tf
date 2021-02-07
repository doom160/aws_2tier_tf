resource "aws_ecr_repository" "go_redis_registry" {
  name                 = "go-redis"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecs_cluster" "go_redis_ecs_cluster" {
  name = "go-redis"
}

resource "aws_ecs_task_definition" "go_redis_task_definition" {
  family                = "go_redis_task_definition"
  container_definitions = file("tasks-definition/container.json")
  requires_compatibilities = ["EC2","FARGATE"]
  execution_role_arn = aws_iam_role.go_redis_iam_role.arn
  task_role_arn = aws_iam_role.go_redis_iam_role.arn
  cpu = 256
  memory = 512
  network_mode = "awsvpc"
}

resource "aws_lb_target_group" "go_redis_target_group" {
  name     = "go-redis"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.go-vpc.id
  target_type = "ip"

  health_check {
    path = "/health"
    healthy_threshold = 5
  }
}

resource "aws_lb" "go_redis_lb" {
  name               = "go-redis"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.allow_all.id ]
  subnets            = aws_subnet.go-public-subnet.*.id

  tags = {
    application = "go-redis"
  }
}

resource "aws_lb_listener" "go_redis_lb_listener" {
  load_balancer_arn = aws_lb.go_redis_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.go_redis_target_group.arn
  }
}

resource "aws_ecs_service" "go_ecs_service" {
  name            = "go-redis"
  cluster         = aws_ecs_cluster.go_redis_ecs_cluster.id
  task_definition = aws_ecs_task_definition.go_redis_task_definition.arn
  desired_count   = 1
  depends_on      = ["aws_lb.go_redis_lb", "aws_lb_target_group.go_redis_target_group"]
  launch_type     = "FARGATE"
  load_balancer {
    target_group_arn = aws_lb_target_group.go_redis_target_group.arn
    container_name   = "app"
    container_port   = 8080
  }
  network_configuration {
    subnets = aws_subnet.go-private-subnet.*.id
    security_groups = [ aws_security_group.internal.id ]
    assign_public_ip = true
  }
}




