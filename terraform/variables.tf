# ──────────────────────────────────────────────────────────────────────
# Input variables — no defaults, user MUST provide all three
# ──────────────────────────────────────────────────────────────────────

# Name of an existing AWS EC2 key pair for SSH access to all instances
variable "key_pair_name" {
  description = "Name of an existing AWS EC2 key pair used for SSH access to all instances"
  type        = string
}

# Your workstation public IP in CIDR notation for bastion SSH access
variable "my_ip" {
  description = "Your workstation public IP in CIDR notation, e.g. 1.2.3.4/32"
  type        = string
}

# ARN of an ACM certificate in eu-north-1 for the HTTPS ALB listener
variable "acm_certificate_arn" {
  description = "ARN of an AWS ACM certificate in eu-north-1 for the ALB HTTPS listener"
  type        = string
}
