# Utilisation du VPC par defaut du compte AWS (0 risque VpcLimitExceeded)
data "aws_vpc" "default" {
  default = true
}

# Subnets existants du VPC par defaut (0 risque de conflit CIDR)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# DB Subnet Group pour RDS
resource "aws_db_subnet_group" "main" {
  name       = "mymusic-db-subnet-group-${local.suffix}"
  subnet_ids = data.aws_subnets.default.ids

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
