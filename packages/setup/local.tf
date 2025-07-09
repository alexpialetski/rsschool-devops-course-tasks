locals {
    bucket_name = "tf-rs-school-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
}