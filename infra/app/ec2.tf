# Selection de l'image officielle Amazon Linux 2023 Standard (exclut les images ECS sans systemd)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Utilisation du VPC par defaut du compte AWS (0 risque VpcLimitExceeded)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group pour l'application principale
resource "aws_security_group" "app" {
  name_prefix = "mymusic-app-sg-"
  description = "Security group pour application principale MyMusic"
  vpc_id      = data.aws_vpc.default.id

  # HTTP direct sur le port 80
  ingress {
    description = "HTTP Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node.js Port 3000
  ingress {
    description = "Node.js Port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH Port 22 pour debug
  ingress {
    description = "SSH Port 22"
    from_port   = 22
    to_port     = 22
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
    Name = "mymusic-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Script User-Data d'initialisation EC2 (octet 0 #!/bin/bash)
locals {
  user_data = <<EOF
#!/bin/bash
exec > >(tee -a /var/log/user-data.log) 2>&1
set -x

echo "=== Initialisation de l'instance EC2 Application MyMusic ==="

# 1. Installation des paquets requis (Node.js natif AL2023, Git, Unzip, AWS CLI)
dnf update -y
dnf install -y nodejs git unzip curl awscli

# 2. Preparation du dossier applicatif
mkdir -p /var/www/mymusic
cd /var/www/mymusic

# 3. Creation du fichier .env connecte a la BDD RDS
cat << EOF_ENV > /var/www/mymusic/.env
PORT=80
HOST=0.0.0.0
NODE_ENV=production
DB_HOST=${var.db_host}
DB_PORT=${var.db_port}
DB_USER=${var.db_user}
DB_PASSWORD=${var.db_password}
DB_NAME=${var.db_name}
EOF_ENV

# 4. Creation du service systemd natif pour MyMusic
cat << 'EOF_SERVICE' > /etc/systemd/system/mymusic.service
[Unit]
Description=MyMusic Main Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/mymusic
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production
Environment=PORT=80
Environment=HOST=0.0.0.0

[Install]
WantedBy=multi-user.target
EOF_SERVICE

systemctl daemon-reload
systemctl enable mymusic

# 5. Telecharger et demarrer la derniere version depuis S3 si disponible
DEPLOY_BUCKET="${aws_s3_bucket.deploy.id}"
if aws s3 ls "s3://$DEPLOY_BUCKET/latest/app.zip" ; then
  aws s3 cp "s3://$DEPLOY_BUCKET/latest/app.zip" app.zip
  unzip -o app.zip
  rm -f app.zip
  npm install --production || true
  systemctl restart mymusic || true
fi

echo "=== Initialisation EC2 terminee avec succes ==="
EOF
}

# 1 seule instance EC2 simple et directe pour l'application principale
resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = local.user_data

  tags = {
    Name = "mymusic-app-server"
  }
}
