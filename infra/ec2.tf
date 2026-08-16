# Data source pour la derniere AMI Amazon Linux 2023
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

# User-data Script pour initialiser l'instance EC2
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > >(tee -a /var/log/user-data.log) 2>&1

    echo "=== Initialisation de l'instance EC2 MyMusic ==="

    # 1. Mise a jour du systeme et installation des outils basiques
    dnf update -y
    dnf install -y git unzip curl awscli

    # 2. Installation de Node.js v20 (LTS)
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    dnf install -y nodejs

    # 3. Installation globale de PM2
    npm install -g pm2 || { echo "Erreur: installation de PM2 a echoue"; exit 1; }
    which pm2
    pm2 --version

    # 4. Preparation du dossier applicatif
    mkdir -p /var/www/mymusic
    cd /var/www/mymusic

    # 5. Telechargement de la derniere release depuis S3 (s'il en existe une)
    DEPLOY_BUCKET="${aws_s3_bucket.deploy.id}"
    echo "Verification du bucket de deploiement: $DEPLOY_BUCKET"

    if aws s3 ls "s3://$DEPLOY_BUCKET/latest/app.zip" ; then
      echo "Telechargement de la release..."
      aws s3 cp "s3://$DEPLOY_BUCKET/latest/app.zip" app.zip
      unzip -o app.zip
      rm -f app.zip
    else
      echo "Aucune release trouvee dans S3 pour l'instant. Attente du premier pipeline."
    fi

    # 6. Generation du fichier .env pour Node.js
    cat << 'EOF_ENV' > /var/www/mymusic/.env
PORT=3000
HOST=0.0.0.0
NODE_ENV=production
AWS_REGION=${var.aws_region}
AWS_S3_BUCKET=${aws_s3_bucket.media.id}
DB_SECRET_ARN=${aws_secretsmanager_secret.db_credentials.arn}
SMTP_SECRET_ARN=${aws_secretsmanager_secret.smtp_credentials.arn}
EOF_ENV

    # 7. Installation des dependances npm et lancement PM2
    if [ -f "package.json" ]; then
      npm install --production || { echo "Erreur: npm install --production a echoue"; exit 1; }

      pm2 delete all || true
      pm2 start server.js --name "mymusic-app" --watch false || { echo "Erreur: demarrage PM2 mymusic-app a echoue"; pm2 logs mymusic-app --lines 200 || true; exit 1; }

      sleep 5
      curl -fsS http://localhost:3000/healthz || { echo "Erreur: health check local a echoue sur localhost:3000"; pm2 logs mymusic-app --lines 200 || true; exit 1; }

      if [ -f "src/service_auxiliere/mail/mail.js" ]; then
        cd src/service_auxiliere/mail
        npm install --production || true
        pm2 start mail.js --name "mymusic-mail" || true
        cd /var/www/mymusic
      fi

      pm2 save
      pm2 startup systemd -u root --hp /root || true
    else
      echo "Erreur: package.json absent dans /var/www/mymusic"
      exit 1
    fi

    echo "=== Initialisation terminee avec succes ==="
  EOF
}

# Launch Template pour l'ASG
resource "aws_launch_template" "app" {
  name_prefix   = "mymusic-launch-template-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = base64encode(local.user_data)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "mymusic-ec2-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "app" {
  name_prefix         = "mymusic-asg-"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  force_delete              = true
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Politique de Target Tracking Auto Scaling basee sur l'utilisation CPU
resource "aws_autoscaling_policy" "cpu_policy" {
  name                   = "mymusic-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60.0
  }
}
