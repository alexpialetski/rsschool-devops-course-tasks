variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "github_actions_role" {
  type = bool
  description = "Enable GitHub Actions role for AWS access"
  default = false
}
