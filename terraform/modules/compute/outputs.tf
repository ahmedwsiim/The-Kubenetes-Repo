# ──────────────────────────────────────────────────────────────────────
# Compute Module — Outputs
# ──────────────────────────────────────────────────────────────────────

output "bastion_public_ip" {
  description = "Public Elastic IP of the bastion host"
  value       = aws_eip.bastion.public_ip
}

output "control_plane_private_ip" {
  description = "Private IP of the control plane node"
  value       = aws_instance.control_plane.private_ip
}

output "worker_1_private_ip" {
  description = "Private IP of worker node 1"
  value       = aws_instance.worker_1.private_ip
}

output "worker_2_private_ip" {
  description = "Private IP of worker node 2"
  value       = aws_instance.worker_2.private_ip
}

# List of worker instance IDs for ALB target group registration
output "worker_instance_ids" {
  description = "List of worker EC2 instance IDs"
  value       = [aws_instance.worker_1.id, aws_instance.worker_2.id]
}
