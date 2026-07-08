# ──────────────────────────────────────────────────────────────────────
# VPC Module — VPC, Subnets, IGW, NAT GW, Route Tables
# ──────────────────────────────────────────────────────────────────────

# Main VPC for the Kubernetes cluster
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

# ── Public Subnets ──────────────────────────────────────────────────

# Public subnets for ALB and bastion (one per AZ)
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-${var.availability_zones[count.index]}" }
}

# ── Private Subnets ─────────────────────────────────────────────────

# Private subnets for all K8s nodes (one per AZ)
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.project_name}-private-${var.availability_zones[count.index]}" }
}

# ── Internet Gateway ────────────────────────────────────────────────

# Internet Gateway for public subnet internet access
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.project_name}-igw" }
}

# ── NAT Gateway ─────────────────────────────────────────────────────

# Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${var.project_name}-nat-eip" }
}

# NAT Gateway in the first public subnet for private node internet access
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.this]

  tags = { Name = "${var.project_name}-nat-gw" }
}

# ── Route Tables ────────────────────────────────────────────────────

# Public route table — sends internet traffic through the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.project_name}-public-rt" }
}

# Default route for public subnets to the Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Private route table — sends internet traffic through the NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.project_name}-private-rt" }
}

# Default route for private subnets through the NAT Gateway
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

# ── Route Table Associations ────────────────────────────────────────

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate each private subnet with the private route table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
