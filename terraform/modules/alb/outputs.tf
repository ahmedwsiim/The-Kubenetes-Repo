# ──────────────────────────────────────────────────────────────────────
# ALB Module — Outputs
# ──────────────────────────────────────────────────────────────────────

# DNS name of the ALB — point your domain CNAME here
output "alb_dns_name" {
  description = "DNS name of the internet-facing ALB"
  value       = aws_lb.main.dns_name
}

# ARN of the ALB
output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}
