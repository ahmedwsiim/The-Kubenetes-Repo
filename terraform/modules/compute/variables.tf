# ──────────────────────────────────────────────────────────────────────
# Compute Module — Input Variables
# ──────────────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name for EBS CSI driver permissions"
  type        = string
}

# ── Subnet IDs ──────────────────────────────────────────────────────

variable "bastion_subnet_id" {
  description = "Public subnet ID for the bastion host"
  type        = string
}

variable "cp_subnet_id" {
  description = "Private subnet ID for the control plane node"
  type        = string
}

variable "worker_1_subnet_id" {
  description = "Private subnet ID for worker node 1"
  type        = string
}

variable "worker_2_subnet_id" {
  description = "Private subnet ID for worker node 2"
  type        = string
}

# ── Security Group IDs ──────────────────────────────────────────────

variable "bastion_sg_id" {
  description = "Security group ID for the bastion host"
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
