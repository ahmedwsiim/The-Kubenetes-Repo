# ──────────────────────────────────────────────────────────────────────
# VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
# ──────────────────────────────────────────────────────────────────────

# Main VPC for the entire Kubernetes cluster
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "k8s-kubeadm-vpc"
  }
}

# ── Public Subnets (for ALB and Bastion) ─────────────────────────────

# Public subnet in AZ eu-north-1a
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-public-subnet-1a"
  }
}

# Public subnet in AZ eu-north-1b
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-public-subnet-1b"
  }
}

# ── Private Subnets (for all EC2 cluster nodes) ─────────────────────

# Private subnet in AZ eu-north-1a (control plane + worker 1)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "k8s-private-subnet-1a"
  }
}

# Private subnet in AZ eu-north-1b (worker 2)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "k8s-private-subnet-1b"
  }
}

# ── Internet Gateway ────────────────────────────────────────────────

# Internet Gateway for public subnet internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "k8s-igw"
  }
}

# ── NAT Gateway ─────────────────────────────────────────────────────

# Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "k8s-nat-eip"
  }
}

# NAT Gateway in the first public subnet so private nodes can reach the internet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "k8s-nat-gw"
  }
}

# ── Route Tables ────────────────────────────────────────────────────

# Public route table — routes internet traffic through the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "k8s-public-rt"
  }
}

# Default route for public subnets to the Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Private route table — routes internet traffic through the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "k8s-private-rt"
  }
}

# Default route for private subnets through the NAT Gateway
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# ── Route Table Associations ────────────────────────────────────────

# Associate public subnet 1 with the public route table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# Associate public subnet 2 with the public route table
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Associate private subnet 1 with the private route table
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

# Associate private subnet 2 with the private route table
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}
