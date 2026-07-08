# ──────────────────────────────────────────────────────────────────────
# Compute Module — AMI data source, Bastion, Control Plane, Workers
# ──────────────────────────────────────────────────────────────────────

# Dynamically fetch the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ── Bastion Host ────────────────────────────────────────────────────

# Bastion host in the public subnet for SSH jump access
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  subnet_id              = var.bastion_subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = { Name = "${var.project_name}-bastion" }
}

# Static Elastic IP for the bastion host
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = { Name = "${var.project_name}-bastion-eip" }
}

# ── Control Plane ───────────────────────────────────────────────────

# Kubernetes control plane node in the first private subnet
resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_pair_name
  subnet_id              = var.cp_subnet_id
  vpc_security_group_ids = [var.control_plane_sg_id]
  iam_instance_profile   = var.instance_profile_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "${var.project_name}-control-plane" }
}

# ── Worker Node 1 ───────────────────────────────────────────────────

# First worker node in private subnet AZ-a
resource "aws_instance" "worker_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_pair_name
  subnet_id              = var.worker_1_subnet_id
  vpc_security_group_ids = [var.worker_sg_id]
  iam_instance_profile   = var.instance_profile_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "${var.project_name}-worker-1" }
}

# ── Worker Node 2 ───────────────────────────────────────────────────

# Second worker node in private subnet AZ-b (cross-AZ redundancy)
resource "aws_instance" "worker_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_pair_name
  subnet_id              = var.worker_2_subnet_id
  vpc_security_group_ids = [var.worker_sg_id]
  iam_instance_profile   = var.instance_profile_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "${var.project_name}-worker-2" }
}
