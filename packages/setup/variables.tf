variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in the format 'owner/repo' for GitHub Actions integration"
  type        = string
  default     = "alexpialetski/rsschool-devops-course-tasks"
}