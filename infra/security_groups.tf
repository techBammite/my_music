# Security Group pour Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "mymusic-alb-sg"
  description = "Autorise le trafic HTTP/HTTPS entrant vers l'ALB"
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
  name        = "mymusic-ec2-sg"
  description = "Autorise le trafic vers l'application Node.js depuis l'ALB uniquement"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Trafic Node.js depuis l'ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Acces Internet sortant via NAT Gateway"
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
  name        = "mymusic-rds-sg"
  description = "Autorise les connexions MySQL depuis les instances EC2 applicatives uniquement"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL depuis EC2 SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Pas d'egress sortant inutile"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mymusic-rds-sg"
  }
}
