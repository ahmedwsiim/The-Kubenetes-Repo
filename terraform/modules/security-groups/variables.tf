# ──────────────────────────────────────────────────────────────────────
# Security Groups Module — Input Variables
# ──────────────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create security groups in"
  type        = string
}

variable "my_ip" {
  description = "Workstation public IP in CIDR notation for bastion SSH access"
  type        = string
}
