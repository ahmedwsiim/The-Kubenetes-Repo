# ──────────────────────────────────────────────────────────────────────
# ALB Module — Load Balancer, Target Groups, Listeners
# ──────────────────────────────────────────────────────────────────────

# Internet-facing Application Load Balancer in both public subnets
resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = { Name = "${var.project_name}-alb" }
}

# ── Target Groups ──────────────────────────────────────────────────

# HTTP target group — Traefik port 80 on workers
resource "aws_lb_target_group" "http" {
  name        = "${var.project_name}-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
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

  tags = { Name = "${var.project_name}-workers-http" }
}

# HTTPS target group — Traefik port 443 on workers
resource "aws_lb_target_group" "https" {
  name        = "${var.project_name}-https"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
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

  tags = { Name = "${var.project_name}-workers-https" }
}

# ── Target Group Attachments ────────────────────────────────────────

# Register each worker into the HTTP target group
resource "aws_lb_target_group_attachment" "http" {
  count = length(var.worker_instance_ids)

  target_group_arn = aws_lb_target_group.http.arn
  target_id        = var.worker_instance_ids[count.index]
  port             = 80
}

# Register each worker into the HTTPS target group
resource "aws_lb_target_group_attachment" "https" {
  count = length(var.worker_instance_ids)

  target_group_arn = aws_lb_target_group.https.arn
  target_id        = var.worker_instance_ids[count.index]
  port             = 443
}

# ── Listeners ───────────────────────────────────────────────────────

# HTTP listener — redirects all traffic to HTTPS (301)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
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

  tags = { Name = "${var.project_name}-http-listener" }
}

# HTTPS listener — forwards to workers with ACM certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }

  tags = { Name = "${var.project_name}-https-listener" }
}
