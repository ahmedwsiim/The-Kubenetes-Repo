# ──────────────────────────────────────────────────────────────────────
# Application Load Balancer, Target Groups, and Listeners
# ──────────────────────────────────────────────────────────────────────

# ── ALB ─────────────────────────────────────────────────────────────

# Internet-facing Application Load Balancer in both public subnets
resource "aws_lb" "main" {
  name               = "k8s-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "k8s-alb"
  }
}

# ── Target Groups ──────────────────────────────────────────────────

# HTTP target group pointing to Traefik port 80 on worker instances
resource "aws_lb_target_group" "http" {
  name     = "k8s-workers-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "80"
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "k8s-workers-http"
  }
}

# HTTPS target group pointing to Traefik port 443 on worker instances
resource "aws_lb_target_group" "https" {
  name     = "k8s-workers-https"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "80"
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "k8s-workers-https"
  }
}

# ── Target Group Attachments ────────────────────────────────────────

# Register worker-1 into the HTTP target group on port 80
resource "aws_lb_target_group_attachment" "worker_1_http" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = aws_instance.worker_1.id
  port             = 80

  depends_on = [aws_instance.worker_1]
}

# Register worker-2 into the HTTP target group on port 80
resource "aws_lb_target_group_attachment" "worker_2_http" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = aws_instance.worker_2.id
  port             = 80

  depends_on = [aws_instance.worker_2]
}

# Register worker-1 into the HTTPS target group on port 443
resource "aws_lb_target_group_attachment" "worker_1_https" {
  target_group_arn = aws_lb_target_group.https.arn
  target_id        = aws_instance.worker_1.id
  port             = 443

  depends_on = [aws_instance.worker_1]
}

# Register worker-2 into the HTTPS target group on port 443
resource "aws_lb_target_group_attachment" "worker_2_https" {
  target_group_arn = aws_lb_target_group.https.arn
  target_id        = aws_instance.worker_2.id
  port             = 443

  depends_on = [aws_instance.worker_2]
}

# ── Listeners ───────────────────────────────────────────────────────

# HTTP listener on port 80 — redirects all traffic to HTTPS
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
    Name = "k8s-alb-http-listener"
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
    Name = "k8s-alb-https-listener"
  }
}
