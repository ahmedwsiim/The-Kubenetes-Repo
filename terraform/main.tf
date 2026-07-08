# ──────────────────────────────────────────────────────────────────────
# Root Module — Provider, locals, and module composition
# ──────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Project     = local.project_name
      Environment = local.environment
      ManagedBy   = "terraform"
    }
  }
}

# ── Locals — single source of truth for all infrastructure sizing ────

locals {
  project_name = "k8s-kubeadm"
  environment  = "learning"
  region       = "eu-north-1"

  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = ["eu-north-1a", "eu-north-1b"]
}

# ── Module: VPC ──────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  project_name         = local.project_name
  vpc_cidr             = local.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  availability_zones   = local.availability_zones
}

# ── Module: Security Groups ─────────────────────────────────────────

module "security_groups" {
  source = "./modules/security-groups"

  project_name = local.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip        = var.my_ip
}

# ── Module: IAM ─────────────────────────────────────────────────────

module "iam" {
  source = "./modules/iam"

  project_name = local.project_name
}

# ── Module: Compute ─────────────────────────────────────────────────

module "compute" {
  source = "./modules/compute"

  project_name          = local.project_name
  key_pair_name         = var.key_pair_name
  instance_profile_name = module.iam.instance_profile_name

  bastion_subnet_id  = module.vpc.public_subnet_ids[0]
  cp_subnet_id       = module.vpc.private_subnet_ids[0]
  worker_1_subnet_id = module.vpc.private_subnet_ids[0]
  worker_2_subnet_id = module.vpc.private_subnet_ids[1]

  bastion_sg_id       = module.security_groups.bastion_sg_id
  control_plane_sg_id = module.security_groups.control_plane_sg_id
  worker_sg_id        = module.security_groups.worker_sg_id
}

# ── Module: ALB ─────────────────────────────────────────────────────

module "alb" {
  source = "./modules/alb"

  project_name        = local.project_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  alb_sg_id           = module.security_groups.alb_sg_id
  worker_instance_ids = module.compute.worker_instance_ids
  acm_certificate_arn = var.acm_certificate_arn
}
