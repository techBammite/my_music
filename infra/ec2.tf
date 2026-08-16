# Selection de l'image officielle Amazon Linux 2023 Standard (exclut les images ECS sans systemd)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# User-data script de premier boot pour tout installer (MariaDB + Node.js + Systemd Service)
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -x

    echo "=== Initialisation de l'instance EC2 MyMusic ==="

    # 1. Installation des paquets requis (MariaDB, Node.js natif AL2023, Git, Unzip, AWS CLI)
    dnf update -y
    dnf install -y mariadb105-server nodejs git unzip curl awscli

    # 2. Demarrage et activation de MariaDB
    systemctl enable mariadb --now

    # 3. Creation de la base de donnees et de l'utilisateur
    mysql -e "CREATE DATABASE IF NOT EXISTS my_music;"
    mysql -e "CREATE USER IF NOT EXISTS 'mymusic_user'@'localhost' IDENTIFIED BY 'MyMusicPassword2026!';"
    mysql -e "GRANT ALL PRIVILEGES ON my_music.* TO 'mymusic_user'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

    # 4. Configuration du dossier applicatif
    mkdir -p /var/www/mymusic
    cd /var/www/mymusic

    # 5. Fichier .env local (Ecoute directe sur le Port 80)
    cat << EOF_ENV > /var/www/mymusic/.env
PORT=80
HOST=0.0.0.0
NODE_ENV=production
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=mymusic_user
DB_PASSWORD=MyMusicPassword2026!
DB_NAME=my_music
EOF_ENV

    # 6. Creation du service systemd natif pour MyMusic
    cat << 'EOF_SERVICE' > /etc/systemd/system/mymusic.service
[Unit]
Description=MyMusic Node.js Application
After=network.target mariadb.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/mymusic
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF_SERVICE

    systemctl daemon-reload
    systemctl enable mymusic

    # 7. Verifier si une premiere version est dispo dans S3
    DEPLOY_BUCKET="${aws_s3_bucket.deploy.id}"
    if aws s3 ls "s3://$DEPLOY_BUCKET/latest/app.zip" ; then
      aws s3 cp "s3://$DEPLOY_BUCKET/latest/app.zip" app.zip
      unzip -o app.zip
      rm -f app.zip
      npm install --production || true
      systemctl restart mymusic || true
    fi

    echo "=== Installation terminee avec succes ==="
  EOF
}

# 1 seule instance EC2 simple avec service systemd natif
resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = local.user_data

  tags = {
    Name = "mymusic-server"
  }
}
