module "github-oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1"

  count = var.github_actions_role ? 1 : 0

  create_oidc_provider = true
  create_oidc_role     = true

  repositories = ["alexpialetski/rsschool-devops-course-tasks"]
  oidc_role_attach_policies = [
    "AmazonSSMFullAccess",
    "AmazonEC2FullAccess",
    "AmazonRoute53FullAccess",
    "AmazonS3FullAccess",
    "IAMFullAccess",
    "AmazonVPCFullAccess",
    "AmazonSQSFullAccess",
    "AmazonEventBridgeFullAccess"
  ]
}
