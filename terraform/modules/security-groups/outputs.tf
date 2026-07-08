# ──────────────────────────────────────────────────────────────────────
# Security Groups Module — Outputs
# ──────────────────────────────────────────────────────────────────────

output "bastion_sg_id" {
  description = "Security group ID for the bastion host"
  value       = aws_security_group.bastion.id
}

output "control_plane_sg_id" {
  description = "Security group ID for the control plane node"
  value       = aws_security_group.control_plane.id
}

output "worker_sg_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.worker.id
}

output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}
