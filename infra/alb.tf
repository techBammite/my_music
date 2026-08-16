# Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "mymusic-alb-${local.suffix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.app_subnet[*].id

  enable_deletion_protection = false

  tags = {
    Name = "mymusic-alb"
  }
}

# Target Group pour les instances EC2 Node.js
resource "aws_lb_target_group" "app" {
  name     = "mymusic-tg-${local.suffix}"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled             = true
    path                = "/healthz"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name = "mymusic-tg"
  }
}

# Listener HTTP sur port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
