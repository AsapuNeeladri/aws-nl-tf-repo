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
  github_repository = "AsapuNeeladri/aws-nl-tf-repo"
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

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions" {
  name = "aws-nl-tf-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_repository}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.id
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
