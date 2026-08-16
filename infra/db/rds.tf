data "aws_availability_zones" "available" {
  state = "available"
}

# Utilisation du VPC par defaut du compte AWS (0 risque VpcLimitExceeded)
data "aws_vpc" "default" {
  default = true
}

# 2 subnets dedies dans 2 AZs distinctes pour le DB Subnet Group de RDS
resource "aws_subnet" "db_subnet" {
  count                   = 2
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 4, count.index + 12)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "mymusic-db-subnet-${count.index + 1}"
  }
}

# DB Subnet Group pour RDS
resource "aws_db_subnet_group" "main" {
  name       = "mymusic-db-subnet-group-${local.suffix}"
  subnet_ids = aws_subnet.db_subnet[*].id

  tags = {
    Name = "mymusic-db-subnet-group"
  }
}

# Security Group pour RDS MySQL (Port 3306 accessible publiquement pour faciliter les tests)
resource "aws_security_group" "rds" {
  name_prefix = "mymusic-db-sg-"
  description = "Security group pour instance RDS MySQL MyMusic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "MySQL access from anywhere for testing"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mymusic-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Instance RDS MySQL 8.0 (Eligible Free Tier db.t3.micro)
resource "aws_db_instance" "mysql" {
  identifier            = "mymusic-db-${local.suffix}"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  parameter_group_name   = "default.mysql8.0"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = false
  publicly_accessible     = true
  skip_final_snapshot     = true
  backup_retention_period = 1

  tags = {
    Name = "mymusic-rds-mysql"
  }
}
