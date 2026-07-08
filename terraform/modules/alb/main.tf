# ──────────────────────────────────────────────────────────────────────
# ALB Module — Load Balancer, Target Groups, Listeners
# ──────────────────────────────────────────────────────────────────────

# Internet-facing Application Load Balancer in both public subnets
resource "aws_lb" "main" {
  name               = "k8s-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = [var.public_subnet_1_id, var.public_subnet_2_id]

  enable_deletion_protection = false

  tags = {
    Name        = "k8s-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Target Groups ──────────────────────────────────────────────────

# HTTP target group — Traefik port 80 on worker instances
resource "aws_lb_target_group" "http" {
  name        = "k8s-workers-http"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name        = "k8s-workers-http"
    Project     = var.project_name
    Environment = var.environment
  }
}

# HTTPS target group — Traefik port 443 on worker instances
resource "aws_lb_target_group" "https" {
  name        = "k8s-workers-https"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name        = "k8s-workers-https"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Target Group Attachments ────────────────────────────────────────

# Register worker 1 into the HTTP target group on port 80
resource "aws_lb_target_group_attachment" "worker_1_http" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = var.worker_1_instance_id
  port             = 80
}

# Register worker 2 into the HTTP target group on port 80
resource "aws_lb_target_group_attachment" "worker_2_http" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = var.worker_2_instance_id
  port             = 80
}

# Register worker 1 into the HTTPS target group on port 443
resource "aws_lb_target_group_attachment" "worker_1_https" {
  target_group_arn = aws_lb_target_group.https.arn
  target_id        = var.worker_1_instance_id
  port             = 443
}

# Register worker 2 into the HTTPS target group on port 443
resource "aws_lb_target_group_attachment" "worker_2_https" {
  target_group_arn = aws_lb_target_group.https.arn
  target_id        = var.worker_2_instance_id
  port             = 443
}

# ── Listeners ───────────────────────────────────────────────────────

# HTTP listener on port 80 — redirects all traffic to HTTPS (301)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "k8s-alb-http-listener"
    Project     = var.project_name
    Environment = var.environment
  }
}

# HTTPS listener on port 443 — forwards to workers with ACM certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }

  tags = {
    Name        = "k8s-alb-https-listener"
    Project     = var.project_name
    Environment = var.environment
  }
}
