# ──────────────────────────────────────────────────────────────────────
# Root Input Variables — user MUST provide all three, no defaults
# ──────────────────────────────────────────────────────────────────────

variable "key_pair_name" {
  description = "Name of an existing AWS EC2 key pair for SSH access to all instances"
  type        = string
}

variable "my_ip" {
  description = "Your workstation public IP in CIDR notation, e.g. 1.2.3.4/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip, 0))
    error_message = "my_ip must be a valid CIDR block, e.g. 1.2.3.4/32"
  }
}

variable "acm_certificate_arn" {
  description = "ARN of an AWS ACM certificate in eu-north-1 for the ALB HTTPS listener"
  type        = string

  validation {
    condition     = startswith(var.acm_certificate_arn, "arn:aws:acm:")
    error_message = "acm_certificate_arn must be a valid ACM ARN starting with arn:aws:acm:"
  }
}
