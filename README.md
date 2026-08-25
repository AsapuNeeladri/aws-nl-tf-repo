# AWS Terraform Lab (Mumbai)

This creates a VPC in `ap-south-1`, public and private subnets, two `t3.micro`
instances, and exactly two S3 buckets:

- A bootstrap bucket for Terraform state and workflow plan files.
- An application bucket used by the public instance through its IAM role.

## Configuration

All Terraform assignments live in `main/local.tf`. Before the first run, make
the S3 bucket names globally unique. The EC2 instances do not require a key
pair and SSH is disabled; add SSM later if administrative access is needed.

The backend cannot read a local, so the state bucket name is intentionally
repeated in `main/provider.tf`, `bootstrap/main.tf`, and the workflow. Keep
these three values synchronized.

## One-time bootstrap

Terraform 1.10 or newer is required for native S3 locking.

```powershell
cd bootstrap
terraform init
terraform apply
```

The bootstrap state remains local because the state bucket does not exist until
this command completes.

## GitHub Actions AWS access

The workflow uses GitHub OIDC, so it does not use access-key secrets. Run the
bootstrap configuration first, then copy the `github_actions_role_arn` output
into a repository variable named `AWS_ROLE_ARN` at **Settings > Secrets and
variables > Actions > Variables**. The repository must be
`AsapuNeeladri/aws-nl-tf-repo`, matching the trust policy in
`bootstrap/main.tf`.

If the role already exists, get its ARN from IAM or run:

```powershell
terraform -chdir=bootstrap output github_actions_role_arn
```

Do not add `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` to this workflow.
The role trust policy permits the `main` branch and pull requests for this
repository, and the workflow's `id-token: write` permission supplies the OIDC
token.

Push to `main`. The workflow validates and plans on pushes and pull requests,
uploads the plan to the state bucket under `plans/latest.tfplan`, and applies
only after a push to `main`.

## Local run

```powershell
cd main
terraform init
terraform plan
terraform apply
```

To avoid charges, run `terraform destroy` from `main`. The bootstrap bucket has
`prevent_destroy` enabled and must be removed separately if required.
