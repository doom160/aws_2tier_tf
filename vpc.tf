# VPC Variables

variable "vpc_cidr" {
	default = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
	default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets_cidr" {
	default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "azs" {
	default = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

# VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = "true" #gives you an internal domain name
  enable_dns_hostnames = "true"  #gives you an internal host name
  enable_classiclink = "false"
  instance_tenancy = "default"    
  tags = {
    env= terraform.workspace
  }
}

# Subnet
resource "aws_subnet" "ecs_public_subnet" {
  count = length(var.public_subnets_cidr)
  vpc_id = aws_vpc.ecs_vpc.id
  cidr_block = element(var.public_subnets_cidr,count.index)
  availability_zone = element(var.azs,count.index)
  tags = {
    env= terraform.workspace
  }
}


# Subnet
resource "aws_subnet" "ecs_private_subnet" {
  count = length(var.private_subnets_cidr)
  vpc_id = aws_vpc.ecs_vpc.id
  cidr_block = element(var.private_subnets_cidr,count.index)
  availability_zone = element(var.azs,count.index)
  tags = {
    env= terraform.workspace
  }
}

resource "aws_nat_gateway" "ecs_nat_gw" {
  allocation_id = aws_eip.ecs_nat_gw_eip.id
  subnet_id     = aws_subnet.ecs_public_subnet[0].id
  depends_on = [aws_internet_gateway.ecs_igw]
  tags = {
    env= terraform.workspace
  }
}

resource "aws_eip" "ecs_nat_gw_eip" {
  vpc      = true
}


# Internet Gateway
resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id
}

# Routing Table
resource "aws_route_table" "ecs_public_rt" {
  vpc_id = aws_vpc.ecs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ecs_igw.id
  }
}

resource "aws_route_table" "ecs_private_rt" {
  vpc_id = aws_vpc.ecs_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ecs_nat_gw.id
  }
}

# Route table association with public subnets
resource "aws_route_table_association" "ecs_associate_public" {
  count =  length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.ecs_public_subnet.*.id,count.index)
  route_table_id = aws_route_table.ecs_public_rt.id
}

# Route table association with private subnets
resource "aws_main_route_table_association" "ecs_associate_private" {
  vpc_id = aws_vpc.ecs_vpc.id
  route_table_id = aws_route_table.ecs_private_rt.id
}

resource "aws_security_group" "internal" {
  name        = "private_rule"
  description = "Allow inbound traffic from network"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow traffic"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

