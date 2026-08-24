locals {
  # Mumbai (ap-south-1) configuration. Change both bucket names below if they
  # are already taken; S3 bucket names are globally unique.
  project_name        = "aws-tf-lab"
  aws_region          = "ap-south-1"
  availability_zone   = "ap-south-1a"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  instance_type       = "t3.micro"

  app_bucket_name = "aws-nl-tf-project-mumbai-2026-001"

  # The plan is uploaded as an object in the state bucket; this keeps the
  # infrastructure to exactly two S3 buckets.
  state_bucket_name = "aws-nl-tf-state-mumbai-2026-001"
  plan_object_key   = "plans/latest.tfplan"
}