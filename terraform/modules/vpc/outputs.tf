# ──────────────────────────────────────────────────────────────────────
# VPC Module — Outputs
# ──────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_1_id" {
  description = "ID of public subnet 1 (eu-north-1a)"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "ID of public subnet 2 (eu-north-1b)"
  value       = aws_subnet.public_2.id
}

output "private_subnet_1_id" {
  description = "ID of private subnet 1 (eu-north-1a)"
  value       = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  description = "ID of private subnet 2 (eu-north-1b)"
  value       = aws_subnet.private_2.id
}
