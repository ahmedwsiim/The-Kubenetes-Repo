# ──────────────────────────────────────────────────────────────────────
# Root Module — Terraform config, provider, and module composition
# ──────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# AWS provider targeting Stockholm region
provider "aws" {
  region = "eu-north-1"
}

# ── Automatically Generate SSH Key Pair ────────────────────────────────

# Generate a 4096-bit RSA private key
resource "tls_private_key" "k8s" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the public key as an AWS Key Pair
resource "aws_key_pair" "k8s" {
  key_name   = "k8s-kubeadm-key"
  public_key = tls_private_key.k8s.public_key_openssh

  tags = {
    Name        = "k8s-kubeadm-key"
    Project     = "k8s-kubeadm"
    Environment = "learning"
  }
}

# Save the private key to a local file for Ansible/SSH access
resource "local_file" "k8s_private_key" {
  content         = tls_private_key.k8s.private_key_pem
  filename        = "${path.module}/k8s-kubeadm.pem"
  file_permission = "0400"
}

# ── Module: VPC & Networking ─────────────────────────────────────────

module "vpc" {
  source       = "./modules/vpc"
  project_name = "k8s-kubeadm"
  environment  = "learning"
}

# ── Module: Security Groups ─────────────────────────────────────────

module "security_groups" {
  source       = "./modules/security-groups"
  vpc_id       = module.vpc.vpc_id
  my_ip        = var.my_ip
  project_name = "k8s-kubeadm"
  environment  = "learning"
}

# ── Module: IAM ─────────────────────────────────────────────────────

module "iam" {
  source       = "./modules/iam"
  project_name = "k8s-kubeadm"
  environment  = "learning"
}

# ── Module: EC2 Instances ───────────────────────────────────────────

module "ec2" {
  source                = "./modules/ec2"
  private_subnet_1_id   = module.vpc.private_subnet_1_id
  private_subnet_2_id   = module.vpc.private_subnet_2_id
  public_subnet_1_id    = module.vpc.public_subnet_1_id
  control_plane_sg_id   = module.security_groups.control_plane_sg_id
  worker_sg_id          = module.security_groups.worker_sg_id
  bastion_sg_id         = module.security_groups.bastion_sg_id
  instance_profile_name = module.iam.instance_profile_name
  key_pair_name         = aws_key_pair.k8s.key_name
  project_name          = "k8s-kubeadm"
  environment           = "learning"
}

# ── Module: ALB ─────────────────────────────────────────────────────

module "alb" {
  source               = "./modules/alb"
  vpc_id               = module.vpc.vpc_id
  public_subnet_1_id   = module.vpc.public_subnet_1_id
  public_subnet_2_id   = module.vpc.public_subnet_2_id
  alb_sg_id            = module.security_groups.alb_sg_id
  worker_1_instance_id = module.ec2.worker_1_instance_id
  worker_2_instance_id = module.ec2.worker_2_instance_id
  acm_certificate_arn  = var.acm_certificate_arn
  project_name         = "k8s-kubeadm"
  environment          = "learning"
}
