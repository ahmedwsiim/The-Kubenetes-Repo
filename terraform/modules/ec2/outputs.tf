# ──────────────────────────────────────────────────────────────────────
# EC2 Module — Outputs
# ──────────────────────────────────────────────────────────────────────

# Public IP of the bastion host for SSH access
output "bastion_public_ip" {
  description = "Public Elastic IP of the bastion host"
  value       = aws_eip.bastion.public_ip
}

# Private IP of the control plane — use for kubeadm init
output "control_plane_private_ip" {
  description = "Private IP of the control plane node"
  value       = aws_instance.control_plane.private_ip
}

# Private IP of worker 1 — use for kubeadm join
output "worker_1_private_ip" {
  description = "Private IP of worker node 1"
  value       = aws_instance.worker_1.private_ip
}

# Private IP of worker 2 — use for kubeadm join
output "worker_2_private_ip" {
  description = "Private IP of worker node 2"
  value       = aws_instance.worker_2.private_ip
}

# Instance ID of worker 1 — used by ALB target group attachment
output "worker_1_instance_id" {
  description = "EC2 instance ID of worker node 1"
  value       = aws_instance.worker_1.id
}

# Instance ID of worker 2 — used by ALB target group attachment
output "worker_2_instance_id" {
  description = "EC2 instance ID of worker node 2"
  value       = aws_instance.worker_2.id
}
