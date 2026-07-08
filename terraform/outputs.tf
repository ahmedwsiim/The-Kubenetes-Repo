# ──────────────────────────────────────────────────────────────────────
# Root Outputs — computed values for post-provisioning use
# ──────────────────────────────────────────────────────────────────────

output "bastion_public_ip" {
  description = "Public Elastic IP of the bastion host — use this to SSH in"
  value       = module.compute.bastion_public_ip
}

output "control_plane_private_ip" {
  description = "Private IP of the control plane node — run kubeadm init here"
  value       = module.compute.control_plane_private_ip
}

output "worker_1_private_ip" {
  description = "Private IP of worker node 1 — run kubeadm join here"
  value       = module.compute.worker_1_private_ip
}

output "worker_2_private_ip" {
  description = "Private IP of worker node 2 — run kubeadm join here"
  value       = module.compute.worker_2_private_ip
}

output "alb_dns_name" {
  description = "DNS name of the ALB — point your domain CNAME here"
  value       = module.alb.alb_dns_name
}

output "vpc_id" {
  description = "ID of the VPC containing the cluster"
  value       = module.vpc.vpc_id
}

# ── Connection cheat-sheet printed after apply ──────────────────────

output "ssh_commands" {
  description = "Quick-start SSH commands"
  value = {
    bastion       = "ssh -i <key>.pem ubuntu@${module.compute.bastion_public_ip}"
    control_plane = "ssh -J ubuntu@${module.compute.bastion_public_ip} ubuntu@${module.compute.control_plane_private_ip}"
    worker_1      = "ssh -J ubuntu@${module.compute.bastion_public_ip} ubuntu@${module.compute.worker_1_private_ip}"
    worker_2      = "ssh -J ubuntu@${module.compute.bastion_public_ip} ubuntu@${module.compute.worker_2_private_ip}"
  }
}
