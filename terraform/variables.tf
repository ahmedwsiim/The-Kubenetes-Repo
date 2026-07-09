# ──────────────────────────────────────────────────────────────────────
# Root Input Variables — user MUST supply all
# ──────────────────────────────────────────────────────────────────────

# Workstation public IP in CIDR notation for bastion SSH access
variable "my_ip" {
  description = "Your workstation public IP in CIDR notation e.g. 1.2.3.4/32"
  type        = string
}

# ACM certificate ARN for the ALB HTTPS listener
variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS listener on ALB"
  type        = string
}
