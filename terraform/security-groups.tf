# ──────────────────────────────────────────────────────────────────────
# Security Groups — all rules as separate resources (no inline rules)
# ──────────────────────────────────────────────────────────────────────

# ═══════════════════════════════════════════════════════════════════════
# 1. BASTION SECURITY GROUP
# ═══════════════════════════════════════════════════════════════════════

# Security group for the bastion host — SSH jump box
resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for the bastion SSH jump host"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "bastion-sg"
  }
}

# Allow SSH inbound from your workstation IP only
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_in" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from workstation"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.my_ip

  tags = { Name = "bastion-ssh-in" }
}

# Allow all outbound traffic from bastion (NAT, apt, SSH to nodes, etc)
resource "aws_vpc_security_group_egress_rule" "bastion_all_out" {
  security_group_id = aws_security_group.bastion.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "bastion-all-out" }
}

# ═══════════════════════════════════════════════════════════════════════
# 2. CONTROL PLANE SECURITY GROUP
# ═══════════════════════════════════════════════════════════════════════

# Security group for the Kubernetes control plane node
resource "aws_security_group" "control_plane" {
  name        = "control-plane-sg"
  description = "Security group for the Kubernetes control plane node"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "control-plane-sg"
  }
}

# Allow SSH from bastion host
resource "aws_vpc_security_group_ingress_rule" "cp_ssh_from_bastion" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "SSH from bastion"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion.id

  tags = { Name = "cp-ssh-from-bastion" }
}

# Allow Kubernetes API server access from worker nodes
resource "aws_vpc_security_group_ingress_rule" "cp_api_from_workers" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "K8s API server from workers"
  ip_protocol                  = "tcp"
  from_port                    = 6443
  to_port                      = 6443
  referenced_security_group_id = aws_security_group.worker.id

  tags = { Name = "cp-api-from-workers" }
}

# Allow Kubernetes API server access from bastion (kubectl via SSH tunnel)
resource "aws_vpc_security_group_ingress_rule" "cp_api_from_bastion" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "K8s API server from bastion (kubectl tunnel)"
  ip_protocol                  = "tcp"
  from_port                    = 6443
  to_port                      = 6443
  referenced_security_group_id = aws_security_group.bastion.id

  tags = { Name = "cp-api-from-bastion" }
}

# Allow etcd client communication from control plane itself
resource "aws_vpc_security_group_ingress_rule" "cp_etcd_client_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "etcd client from self"
  ip_protocol                  = "tcp"
  from_port                    = 2379
  to_port                      = 2379
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = { Name = "cp-etcd-client-self" }
}

# Allow etcd peer communication from control plane itself
resource "aws_vpc_security_group_ingress_rule" "cp_etcd_peer_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "etcd peer from self"
  ip_protocol                  = "tcp"
  from_port                    = 2380
  to_port                      = 2380
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = { Name = "cp-etcd-peer-self" }
}

# Allow kubelet API from worker nodes
resource "aws_vpc_security_group_ingress_rule" "cp_kubelet_from_workers" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kubelet from workers"
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.worker.id

  tags = { Name = "cp-kubelet-from-workers" }
}

# Allow kubelet API from control plane itself
resource "aws_vpc_security_group_ingress_rule" "cp_kubelet_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kubelet from self"
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = { Name = "cp-kubelet-self" }
}

# Allow kube-controller-manager from control plane itself
resource "aws_vpc_security_group_ingress_rule" "cp_controller_manager_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kube-controller-manager from self"
  ip_protocol                  = "tcp"
  from_port                    = 10257
  to_port                      = 10257
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = { Name = "cp-controller-manager-self" }
}

# Allow kube-scheduler from control plane itself
resource "aws_vpc_security_group_ingress_rule" "cp_scheduler_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kube-scheduler from self"
  ip_protocol                  = "tcp"
  from_port                    = 10259
  to_port                      = 10259
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = { Name = "cp-scheduler-self" }
}

# Allow all outbound traffic from control plane (NAT, image pulls, etc)
resource "aws_vpc_security_group_egress_rule" "cp_all_out" {
  security_group_id = aws_security_group.control_plane.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "cp-all-out" }
}

# ═══════════════════════════════════════════════════════════════════════
# 3. WORKER SECURITY GROUP
# ═══════════════════════════════════════════════════════════════════════

# Security group for Kubernetes worker nodes
resource "aws_security_group" "worker" {
  name        = "worker-sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "worker-sg"
  }
}

# Allow SSH from bastion host
resource "aws_vpc_security_group_ingress_rule" "worker_ssh_from_bastion" {
  security_group_id            = aws_security_group.worker.id
  description                  = "SSH from bastion"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion.id

  tags = { Name = "worker-ssh-from-bastion" }
}

# Allow kubelet API from control plane
resource "aws_vpc_security_group_ingress_rule" "worker_kubelet_from_cp" {
  security_group_id            = aws_security_group.worker.id
  description                  = "kubelet from control plane"
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = { Name = "worker-kubelet-from-cp" }
}

# Allow HTTP from ALB (Traefik hostPort 80)
resource "aws_vpc_security_group_ingress_rule" "worker_http_from_alb" {
  security_group_id            = aws_security_group.worker.id
  description                  = "HTTP from ALB to Traefik hostPort"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id

  tags = { Name = "worker-http-from-alb" }
}

# Allow HTTPS from ALB (Traefik hostPort 443)
resource "aws_vpc_security_group_ingress_rule" "worker_https_from_alb" {
  security_group_id            = aws_security_group.worker.id
  description                  = "HTTPS from ALB to Traefik hostPort"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.alb.id

  tags = { Name = "worker-https-from-alb" }
}

# Allow Traefik dashboard from bastion only (port 9000, internal access)
resource "aws_vpc_security_group_ingress_rule" "worker_dashboard_from_bastion" {
  security_group_id            = aws_security_group.worker.id
  description                  = "Traefik dashboard from bastion"
  ip_protocol                  = "tcp"
  from_port                    = 9000
  to_port                      = 9000
  referenced_security_group_id = aws_security_group.bastion.id

  tags = { Name = "worker-dashboard-from-bastion" }
}

# Allow NodePort range from control plane (cluster internal traffic)
resource "aws_vpc_security_group_ingress_rule" "worker_nodeport_from_cp" {
  security_group_id            = aws_security_group.worker.id
  description                  = "NodePort range from control plane"
  ip_protocol                  = "tcp"
  from_port                    = 30000
  to_port                      = 32767
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = { Name = "worker-nodeport-from-cp" }
}

# Allow all traffic from other worker nodes (pod-to-pod via Calico)
resource "aws_vpc_security_group_ingress_rule" "worker_all_from_workers" {
  security_group_id            = aws_security_group.worker.id
  description                  = "All traffic from other workers (Calico pod-to-pod)"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.worker.id

  tags = { Name = "worker-all-from-workers" }
}

# Allow all traffic from control plane (cluster internal communication)
resource "aws_vpc_security_group_ingress_rule" "worker_all_from_cp" {
  security_group_id            = aws_security_group.worker.id
  description                  = "All traffic from control plane (cluster internal)"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = { Name = "worker-all-from-cp" }
}

# Allow all outbound traffic from worker nodes (NAT, image pulls, etc)
resource "aws_vpc_security_group_egress_rule" "worker_all_out" {
  security_group_id = aws_security_group.worker.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "worker-all-out" }
}

# ═══════════════════════════════════════════════════════════════════════
# 4. ALB SECURITY GROUP
# ═══════════════════════════════════════════════════════════════════════

# Security group for the internet-facing Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Security group for the internet-facing ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "alb-sg"
  }
}

# Allow HTTP inbound from the entire internet
resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "alb-http-in" }
}

# Allow HTTPS inbound from the entire internet
resource "aws_vpc_security_group_ingress_rule" "alb_https_in" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"

  tags = { Name = "alb-https-in" }
}

# Allow HTTP outbound to worker nodes only
resource "aws_vpc_security_group_egress_rule" "alb_http_to_workers" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTP to worker nodes"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.worker.id

  tags = { Name = "alb-http-to-workers" }
}

# Allow HTTPS outbound to worker nodes only
resource "aws_vpc_security_group_egress_rule" "alb_https_to_workers" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTPS to worker nodes"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.worker.id

  tags = { Name = "alb-https-to-workers" }
}
