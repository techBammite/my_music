# Subnet Group pour RDS dans les subnets du VPC par defaut
resource "aws_db_subnet_group" "main" {
  name       = "mymusic-db-subnet-group-${local.suffix}"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "mymusic-db-subnet-group"
  }
}

# Instance RDS MySQL
resource "aws_db_instance" "mysql" {
  identifier            = "mymusic-db-${local.suffix}"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  db_name               = var.db_name
  username              = var.db_username
  password              = random_password.db_password.result
  parameter_group_name  = "default.mysql8.0"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = var.multi_az_db
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 1

  tags = {
    Name = "mymusic-rds-mysql"
  }
}
