# ──────────────────────────────────────────────────────────────────────
# IAM Module — Input Variables
# ──────────────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
}
