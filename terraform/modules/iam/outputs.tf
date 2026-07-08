# ──────────────────────────────────────────────────────────────────────
# IAM Module — Outputs
# ──────────────────────────────────────────────────────────────────────

output "instance_profile_name" {
  description = "Name of the IAM instance profile for EC2 nodes"
  value       = aws_iam_instance_profile.ec2_ebs.name
}

output "role_arn" {
  description = "ARN of the IAM role for EBS operations"
  value       = aws_iam_role.ec2_ebs.arn
}
