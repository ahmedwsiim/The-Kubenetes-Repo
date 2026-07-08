# ──────────────────────────────────────────────────────────────────────
# IAM resources for the EBS CSI Driver (kubeadm — no IRSA available)
# ──────────────────────────────────────────────────────────────────────

# IAM policy granting EC2 EBS volume management permissions for the CSI driver
resource "aws_iam_policy" "ebs_csi_driver" {
  name        = "EbsCsiDriverPolicy"
  description = "Allows EC2 instances to manage EBS volumes for the Kubernetes EBS CSI Driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EbsVolumeManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeInstances",
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "EbsCsiDriverPolicy"
  }
}

# IAM role that EC2 instances can assume for EBS operations
resource "aws_iam_role" "ec2_ebs" {
  name        = "ec2-ebs-role"
  description = "IAM role for EC2 instances to manage EBS volumes via the CSI driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEC2Assume"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ec2-ebs-role"
  }
}

# Attach the EBS CSI policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ec2_ebs.name
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
}

# Instance profile that links the IAM role to EC2 instances
resource "aws_iam_instance_profile" "ec2_ebs" {
  name = "ec2-ebs-profile"
  role = aws_iam_role.ec2_ebs.name

  tags = {
    Name = "ec2-ebs-profile"
  }
}
