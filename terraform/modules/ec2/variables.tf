# ──────────────────────────────────────────────────────────────────────
# EC2 Module — Input Variables
# ──────────────────────────────────────────────────────────────────────

variable "private_subnet_1_id" {
  description = "Private subnet ID in AZ-a (control plane + worker 1)"
  type        = string
}

variable "private_subnet_2_id" {
  description = "Private subnet ID in AZ-b (worker 2)"
  type        = string
}

variable "public_subnet_1_id" {
  description = "Public subnet ID in AZ-a (bastion host)"
  type        = string
}

variable "control_plane_sg_id" {
  description = "Security group ID for the control plane node"
  type        = string
}

variable "worker_sg_id" {
  description = "Security group ID for worker nodes"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for the bastion host"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EBS CSI driver permissions"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
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
