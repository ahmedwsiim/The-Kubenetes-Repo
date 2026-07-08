# ──────────────────────────────────────────────────────────────────────
# EC2 Module — AMI data source, Bastion, Control Plane, Workers
# ──────────────────────────────────────────────────────────────────────

# Dynamically fetch the latest Ubuntu 22.04 LTS AMI for eu-north-1
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Control Plane ───────────────────────────────────────────────────

# Kubernetes control plane node in private subnet 1a
resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = var.private_subnet_1_id
  vpc_security_group_ids = [var.control_plane_sg_id]
  key_name               = var.key_pair_name
  iam_instance_profile   = var.instance_profile_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name        = "k8s-control-plane"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Worker Node 1 ───────────────────────────────────────────────────

# First Kubernetes worker node in private subnet 1a
resource "aws_instance" "worker_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = var.private_subnet_1_id
  vpc_security_group_ids = [var.worker_sg_id]
  key_name               = var.key_pair_name
  iam_instance_profile   = var.instance_profile_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name        = "k8s-worker-1"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Worker Node 2 ───────────────────────────────────────────────────

# Second Kubernetes worker node in private subnet 1b (cross-AZ)
resource "aws_instance" "worker_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = var.private_subnet_2_id
  vpc_security_group_ids = [var.worker_sg_id]
  key_name               = var.key_pair_name
  iam_instance_profile   = var.instance_profile_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name        = "k8s-worker-2"
    Project     = var.project_name
    Environment = var.environment
  }
}

# ── Bastion Host ────────────────────────────────────────────────────

# Bastion host in the public subnet for SSH jump access
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_1_id
  vpc_security_group_ids = [var.bastion_sg_id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name        = "k8s-bastion"
    Project     = var.project_name
    Environment = var.environment
  }
}

# Static Elastic IP for the bastion host
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-bastion-eip"
    Project     = var.project_name
    Environment = var.environment
  }
}
