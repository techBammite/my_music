data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
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

# User-data script de premier boot pour tout installer (MariaDB + Node.js + PM2 + Nginx)
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -ex
    exec > >(tee -a /var/log/user-data.log) 2>&1

    echo "=== Initialisation de l'instance EC2 MyMusic (Single Instance) ==="

    # 1. Installation des paquets requis
    dnf update -y
    dnf install -y mariadb105-server git unzip curl awscli nginx

    # 2. Demarrage et activation de MariaDB
    systemctl enable mariadb
    systemctl start mariadb

    # 3. Creation de la base de donnees et de l'utilisateur
    mysql -e "CREATE DATABASE IF NOT EXISTS my_music;"
    mysql -e "CREATE USER IF NOT EXISTS 'mymusic_user'@'localhost' IDENTIFIED BY 'MyMusicPassword2026!';"
    mysql -e "GRANT ALL PRIVILEGES ON my_music.* TO 'mymusic_user'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

    # 4. Installation de Node.js v20 (LTS) & PM2
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    dnf install -y nodejs
    npm install -g pm2

    # 5. Configuration du dossier applicatif
    mkdir -p /var/www/mymusic
    cd /var/www/mymusic

    # 6. Fichier .env local ultra-simple
    cat << EOF_ENV > /var/www/mymusic/.env
PORT=3000
HOST=0.0.0.0
NODE_ENV=production
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=mymusic_user
DB_PASSWORD=MyMusicPassword2026!
DB_NAME=my_music
EOF_ENV

    # 7. Configuration de Nginx pour rediriger le port 80 vers Node.js (port 3000)
    cat << 'EOF_NGINX' > /etc/nginx/conf.d/mymusic.conf
server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF_NGINX

    systemctl enable nginx
    systemctl restart nginx

    # 8. Verifier si une premiere version est dispo dans S3
    DEPLOY_BUCKET="${aws_s3_bucket.deploy.id}"
    if aws s3 ls "s3://$DEPLOY_BUCKET/latest/app.zip" ; then
      aws s3 cp "s3://$DEPLOY_BUCKET/latest/app.zip" app.zip
      unzip -o app.zip
      rm -f app.zip
      npm install --production || true
      pm2 start server.js --name "mymusic" || true
      pm2 save
      pm2 startup systemd -u root --hp /root || true
    fi

    echo "=== Installation terminee avec succes ==="
  EOF
}

# 1 seule instance EC2 simple et robuste (0 ASG, 0 ALB)
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data                   = base64encode(local.user_data)
  associate_public_ip_address = true

  tags = {
    Name = "mymusic-server"
  }
}
