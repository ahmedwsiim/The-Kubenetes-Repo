# ──────────────────────────────────────────────────────────────────────
# Root Outputs — final computed values from all modules
# ──────────────────────────────────────────────────────────────────────

# Public IP of the bastion host for SSH access
output "bastion_public_ip" {
  description = "Public Elastic IP of the bastion host"
  value       = module.ec2.bastion_public_ip
}

# Private IP of the control plane — run kubeadm init here
output "control_plane_private_ip" {
  description = "Private IP of the Kubernetes control plane node"
  value       = module.ec2.control_plane_private_ip
}

# Private IP of worker 1 — run kubeadm join here
output "worker_1_private_ip" {
  description = "Private IP of Kubernetes worker node 1"
  value       = module.ec2.worker_1_private_ip
}

# Private IP of worker 2 — run kubeadm join here
output "worker_2_private_ip" {
  description = "Private IP of Kubernetes worker node 2"
  value       = module.ec2.worker_2_private_ip
}

# DNS name of the ALB — point your domain CNAME here
output "alb_dns_name" {
  description = "DNS name of the internet-facing Application Load Balancer"
  value       = module.alb.alb_dns_name
}

# VPC ID for reference
output "vpc_id" {
  description = "ID of the VPC containing the Kubernetes cluster"
  value       = module.vpc.vpc_id
}
