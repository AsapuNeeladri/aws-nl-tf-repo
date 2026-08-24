terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Backend configuration cannot reference locals. Keep this in sync with
    # local.state_bucket_name below and bootstrap/local.tf.
    bucket       = "aws-nl-tf-state-mumbai-2026-001"
    key          = "aws-lab/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # S3 native locking (Terraform >= 1.10) - no DynamoDB needed
  }
}

provider "aws" {
  region = local.aws_region
}
