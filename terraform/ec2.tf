# ──────────────────────────────────────────────────────────────────────
# EC2 Instances — AMI data source, Control Plane, Workers, Bastion
# ──────────────────────────────────────────────────────────────────────

# Dynamically fetch the latest Ubuntu 22.04 LTS AMI for eu-north-1
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

# Bastion host in the public subnet for SSH access to private nodes
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-bastion"
  }
}

# Elastic IP for the bastion host so its public IP never changes
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "k8s-bastion-eip"
  }
}

# ── Control Plane Node ──────────────────────────────────────────────

# Kubernetes control plane node running kubeadm in the first private subnet
resource "aws_instance" "control_plane" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.control_plane.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ebs.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-control-plane"
  }
}

# ── Worker Node 1 ───────────────────────────────────────────────────

# First Kubernetes worker node in private subnet 1a
resource "aws_instance" "worker_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.worker.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ebs.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-worker-1"
  }
}

# ── Worker Node 2 ───────────────────────────────────────────────────

# Second Kubernetes worker node in private subnet 1b (different AZ)
resource "aws_instance" "worker_2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.worker.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ebs.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "k8s-worker-2"
  }
}
