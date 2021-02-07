
resource "aws_elasticache_subnet_group" "go-subnet-group" {
  name       = "elasticache-subnet-group"
  subnet_ids = aws_subnet.go-public-subnet.*.id
}

resource "aws_elasticache_cluster" "go_elasticache" {
  cluster_id           = "go-elasticache"
  subnet_group_name    = aws_elasticache_subnet_group.go-subnet-group.name
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
  security_group_ids   = [aws_security_group.allow_all.id]
  tags = {
    application="go-redis"
  }
}