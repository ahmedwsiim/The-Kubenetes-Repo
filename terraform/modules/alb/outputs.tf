# ──────────────────────────────────────────────────────────────────────
# ALB Module — Outputs
# ──────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "DNS name of the ALB — point your domain CNAME here"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.this.arn
}

output "alb_zone_id" {
  description = "Route53 hosted zone ID of the ALB (for alias records)"
  value       = aws_lb.this.zone_id
}
