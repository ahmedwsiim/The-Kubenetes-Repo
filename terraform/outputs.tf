# ──────────────────────────────────────────────────────────────────────
# Outputs — computed values for post-provisioning configuration
# ──────────────────────────────────────────────────────────────────────

# Public IP of the bastion host for SSH access
output "bastion_public_ip" {
  description = "Public Elastic IP of the bastion host"
  value       = aws_eip.bastion.public_ip
}

# Private IP of the control plane node for kubeadm init
output "control_plane_private_ip" {
  description = "Private IP of the Kubernetes control plane node"
  value       = aws_instance.control_plane.private_ip
}

# Private IP of worker node 1 for kubeadm join
output "worker_1_private_ip" {
  description = "Private IP of Kubernetes worker node 1"
  value       = aws_instance.worker_1.private_ip
}

# Private IP of worker node 2 for kubeadm join
output "worker_2_private_ip" {
  description = "Private IP of Kubernetes worker node 2"
  value       = aws_instance.worker_2.private_ip
}

# DNS name of the ALB for CNAME or alias DNS records
output "alb_dns_name" {
  description = "DNS name of the internet-facing Application Load Balancer"
  value       = aws_lb.main.dns_name
}

# VPC ID for reference in post-provisioning scripts
output "vpc_id" {
  description = "ID of the VPC containing the Kubernetes cluster"
  value       = aws_vpc.main.id
}
