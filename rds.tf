variable "rds_instance_type" {
	default = "db.t3.small"
}

variable "rds_admin_user" {
	default = "admin"
}

variable "rds_admin_password" {
	default = "rootpassword123"
}

variable "rds_database_name" {
    default = "test"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = "${terraform.workspace}-node-app-rds"

  engine            = "mysql"
  engine_version    = "8.0.20"
  instance_class    = var.rds_instance_type
  allocated_storage = 20

  name     = var.rds_database_name
  username = var.rds_admin_user
  password =  var.rds_admin_password
  port     = "3306"

  vpc_security_group_ids = [ aws_security_group.internal.id ]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  create_monitoring_role = false

  # DB subnet group
  subnet_ids = aws_subnet.ecs_private_subnet.*.id

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "demodb"

  # Database Deletion Protection
  deletion_protection = true

  multi_az = true

  parameters = [
  ]

  options = [
     
  ]

  tags = {
    env= terraform.workspace
  }
}