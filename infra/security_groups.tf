# Security Group pour Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "mymusic-alb-sg-${random_id.suffix.hex}"
  description = "Autorise le trafic HTTP et HTTPS entrant vers ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS depuis Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Egress vers instances EC2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mymusic-alb-sg"
  }
}

# Security Group pour les instances EC2 App
resource "aws_security_group" "ec2" {
  name        = "mymusic-ec2-sg-${random_id.suffix.hex}"
  description = "Autorise le trafic vers application Node.js depuis ALB uniquement"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Trafic Node.js depuis ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Acces Internet sortant"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mymusic-ec2-sg"
  }
}

# Security Group pour la base de donnees RDS MySQL
resource "aws_security_group" "rds" {
  name        = "mymusic-rds-sg-${random_id.suffix.hex}"
  description = "Autorise les connexions MySQL depuis EC2 uniquement"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL depuis EC2 SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Egress sortant RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mymusic-rds-sg"
  }
}
