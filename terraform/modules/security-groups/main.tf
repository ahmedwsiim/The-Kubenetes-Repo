# ──────────────────────────────────────────────────────────────────────
# Security Groups Module — 4 SGs with all rules as separate resources
# ──────────────────────────────────────────────────────────────────────

# ═══════════════════════════════════════════════════════════════════════
# 1. BASTION SECURITY GROUP
# ═══════════════════════════════════════════════════════════════════════

# Security group for the bastion SSH jump host
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion SSH jump host"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-bastion-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow SSH inbound from workstation IP only
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_in" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from workstation"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.my_ip

  tags = {
    Name        = "${var.project_name}-bastion-ssh-in"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow SSH outbound to all private nodes in the VPC
resource "aws_vpc_security_group_egress_rule" "bastion_ssh_to_vpc" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH to VPC private nodes"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "10.0.0.0/16"

  tags = {
    Name        = "${var.project_name}-bastion-ssh-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow all outbound traffic from bastion (apt updates, NAT, etc)
resource "aws_vpc_security_group_egress_rule" "bastion_all_out" {
  security_group_id = aws_security_group.bastion.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name        = "${var.project_name}-bastion-all-out"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ═══════════════════════════════════════════════════════════════════════
# 2. CONTROL PLANE SECURITY GROUP
# ═══════════════════════════════════════════════════════════════════════

# Security group for the Kubernetes control plane node
resource "aws_security_group" "control_plane" {
  name        = "${var.project_name}-control-plane-sg"
  description = "Kubernetes control plane node"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-control-plane-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow SSH from bastion
resource "aws_vpc_security_group_ingress_rule" "cp_ssh_from_bastion" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "SSH from bastion"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion.id

  tags = {
    Name        = "${var.project_name}-cp-ssh-bastion"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow K8s API server from workers
resource "aws_vpc_security_group_ingress_rule" "cp_api_from_workers" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "K8s API from workers"
  ip_protocol                  = "tcp"
  from_port                    = 6443
  to_port                      = 6443
  referenced_security_group_id = aws_security_group.worker.id

  tags = {
    Name        = "${var.project_name}-cp-api-workers"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow K8s API server from bastion (kubectl via SSH tunnel)
resource "aws_vpc_security_group_ingress_rule" "cp_api_from_bastion" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "K8s API from bastion (kubectl tunnel)"
  ip_protocol                  = "tcp"
  from_port                    = 6443
  to_port                      = 6443
  referenced_security_group_id = aws_security_group.bastion.id

  tags = {
    Name        = "${var.project_name}-cp-api-bastion"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow etcd client from control plane itself
resource "aws_vpc_security_group_ingress_rule" "cp_etcd_client_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "etcd client from self"
  ip_protocol                  = "tcp"
  from_port                    = 2379
  to_port                      = 2379
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name        = "${var.project_name}-cp-etcd-client"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow etcd peer from control plane itself
resource "aws_vpc_security_group_ingress_rule" "cp_etcd_peer_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "etcd peer from self"
  ip_protocol                  = "tcp"
  from_port                    = 2380
  to_port                      = 2380
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name        = "${var.project_name}-cp-etcd-peer"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow kubelet from workers
resource "aws_vpc_security_group_ingress_rule" "cp_kubelet_from_workers" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kubelet from workers"
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.worker.id

  tags = {
    Name        = "${var.project_name}-cp-kubelet-workers"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow kubelet from control plane itself
resource "aws_vpc_security_group_ingress_rule" "cp_kubelet_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kubelet from self"
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name        = "${var.project_name}-cp-kubelet-self"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow kube-controller-manager from self
resource "aws_vpc_security_group_ingress_rule" "cp_controller_manager_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kube-controller-manager from self"
  ip_protocol                  = "tcp"
  from_port                    = 10257
  to_port                      = 10257
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name        = "${var.project_name}-cp-ctrl-mgr"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow kube-scheduler from self
resource "aws_vpc_security_group_ingress_rule" "cp_scheduler_self" {
  security_group_id            = aws_security_group.control_plane.id
  description                  = "kube-scheduler from self"
  ip_protocol                  = "tcp"
  from_port                    = 10259
  to_port                      = 10259
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name        = "${var.project_name}-cp-scheduler"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow all outbound from control plane
resource "aws_vpc_security_group_egress_rule" "cp_all_out" {
  security_group_id = aws_security_group.control_plane.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name        = "${var.project_name}-cp-all-out"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ═══════════════════════════════════════════════════════════════════════
# 3. WORKER SECURITY GROUP
# ═══════════════════════════════════════════════════════════════════════

# Security group for Kubernetes worker nodes
resource "aws_security_group" "worker" {
  name        = "${var.project_name}-worker-sg"
  description = "Kubernetes worker nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-worker-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow SSH from bastion
resource "aws_vpc_security_group_ingress_rule" "worker_ssh_from_bastion" {
  security_group_id            = aws_security_group.worker.id
  description                  = "SSH from bastion"
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.bastion.id

  tags = {
    Name        = "${var.project_name}-worker-ssh-bastion"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow kubelet from control plane
resource "aws_vpc_security_group_ingress_rule" "worker_kubelet_from_cp" {
  security_group_id            = aws_security_group.worker.id
  description                  = "kubelet from control plane"
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name        = "${var.project_name}-worker-kubelet-cp"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow HTTP from ALB (Traefik hostPort 80)
resource "aws_vpc_security_group_ingress_rule" "worker_http_from_alb" {
  security_group_id            = aws_security_group.worker.id
  description                  = "HTTP from ALB to Traefik"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name        = "${var.project_name}-worker-http-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow HTTPS from ALB (Traefik hostPort 443)
resource "aws_vpc_security_group_ingress_rule" "worker_https_from_alb" {
  security_group_id            = aws_security_group.worker.id
  description                  = "HTTPS from ALB to Traefik"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name        = "${var.project_name}-worker-https-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow Traefik dashboard from bastion only (port 9000)
resource "aws_vpc_security_group_ingress_rule" "worker_dashboard_from_bastion" {
  security_group_id            = aws_security_group.worker.id
  description                  = "Traefik dashboard from bastion"
  ip_protocol                  = "tcp"
  from_port                    = 9000
  to_port                      = 9000
  referenced_security_group_id = aws_security_group.bastion.id

  tags = {
    Name        = "${var.project_name}-worker-dash-bastion"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow NodePort range from control plane
resource "aws_vpc_security_group_ingress_rule" "worker_nodeport_from_cp" {
  security_group_id            = aws_security_group.worker.id
  description                  = "NodePort range from control plane"
  ip_protocol                  = "tcp"
  from_port                    = 30000
  to_port                      = 32767
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name        = "${var.project_name}-worker-nodeport-cp"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow all traffic from other workers (Calico pod-to-pod)
resource "aws_vpc_security_group_ingress_rule" "worker_all_from_workers" {
  security_group_id            = aws_security_group.worker.id
  description                  = "All from workers (Calico pod-to-pod)"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.worker.id

  tags = {
    Name        = "${var.project_name}-worker-all-workers"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow all traffic from control plane (cluster internal)
resource "aws_vpc_security_group_ingress_rule" "worker_all_from_cp" {
  security_group_id            = aws_security_group.worker.id
  description                  = "All from control plane (cluster internal)"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.control_plane.id

  tags = {
    Name        = "${var.project_name}-worker-all-cp"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow all outbound from workers
resource "aws_vpc_security_group_egress_rule" "worker_all_out" {
  security_group_id = aws_security_group.worker.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name        = "${var.project_name}-worker-all-out"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ═══════════════════════════════════════════════════════════════════════
# 4. ALB SECURITY GROUP
# ═══════════════════════════════════════════════════════════════════════

# Security group for the internet-facing ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Internet-facing Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow HTTP from the internet
resource "aws_vpc_security_group_ingress_rule" "alb_http_in" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name        = "${var.project_name}-alb-http-in"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow HTTPS from the internet
resource "aws_vpc_security_group_ingress_rule" "alb_https_in" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name        = "${var.project_name}-alb-https-in"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow HTTP outbound to workers only
resource "aws_vpc_security_group_egress_rule" "alb_http_to_workers" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTP to workers"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.worker.id

  tags = {
    Name        = "${var.project_name}-alb-http-workers"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Allow HTTPS outbound to workers only
resource "aws_vpc_security_group_egress_rule" "alb_https_to_workers" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTPS to workers"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.worker.id

  tags = {
    Name        = "${var.project_name}-alb-https-workers"
    Project     = var.project_name
    Environment = var.environment
  }
}
