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
    exec > >(tee /var/log/user-data.log|tag -t user-data) 2>&1

    echo "=== Initialisation de l'instance EC2 MyMusic ==="

    # 1. Mise a jour du systeme et installation des outils basiques
    dnf update -y
    dnf install -y git unzip curl awscli

    # 2. Installation de Node.js v20 (LTS)
    curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
    dnf install -y nodejs

    # 3. Installation globale de PM2
    npm install -y -g pm2

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

    # 6. Installation des dependances npm si package.json existe
    if [ -f "package.json" ]; then
      npm install --production

      # Definition des variables d'environnement
      export PORT=3000
      export NODE_ENV=production
      export AWS_REGION="${var.aws_region}"
      export AWS_S3_BUCKET="${aws_s3_bucket.media.id}"
      export DB_SECRET_ARN="${aws_secretsmanager_secret.db_credentials.arn}"
      export SMTP_SECRET_ARN="${aws_secretsmanager_secret.smtp_credentials.arn}"

      # Lancement de l'application via PM2
      pm2 start server.js --name "mymusic-app"
      
      if [ -f "src/service_auxiliere/mail/mail.js" ]; then
        cd src/service_auxiliere/mail && npm install --production && pm2 start mail.js --name "mymusic-mail" && cd /var/www/mymusic
      fi

      pm2 save
      pm2 startup systemd -u root --hp /root || true
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
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = base64encode(local.user_data)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 requis pour la securite
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
  vpc_zone_identifier = aws_subnet.private_app[*].id
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
