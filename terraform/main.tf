# ──────────────────────────────────────────────────────────────────────
# Terraform configuration and AWS provider setup
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

# AWS provider configured for Stockholm region with default resource tags
provider "aws" {
  region = "eu-north-1"

  default_tags {
    tags = {
      Project     = "k8s-kubeadm"
      Environment = "learning"
    }
  }
}
