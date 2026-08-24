########################################
# BOOTSTRAP - run this ONCE, manually
# Creates the S3 bucket that holds your Terraform
# state file. Locking uses Terraform's native S3
# locking feature (use_lockfile), so no DynamoDB
# table is needed. Requires Terraform >= 1.10.
#
# This folder keeps its own state LOCAL, because the
# bucket it creates doesn't exist yet when it runs.
########################################

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  state_bucket_name = "aws-nl-tf-state-mumbai-2026-001"
  aws_region        = "ap-south-1"
}

provider "aws" {
  region = local.aws_region
}

resource "aws_s3_bucket" "tf_state" {
  bucket = local.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

# Versioning gives you a rollback path if state ever gets corrupted -
# S3 native locking prevents concurrent writes, but versioning is
# still good practice on a state bucket.
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.id
}
