# ──────────────────────────────────────────────────────────────────────
# Security Groups Module — Input Variables
# ──────────────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "ID of the VPC to create security groups in"
  type        = string
}

variable "my_ip" {
  description = "Workstation public IP in CIDR notation for bastion SSH access"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
}
