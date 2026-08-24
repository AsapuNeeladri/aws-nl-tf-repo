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

This initial workflow uses an IAM access key because no dedicated deployment
role exists yet. Create an IAM user for deployment, grant it the permissions
needed by Terraform and S3 state locking, and add these repository secrets at
**Settings > Secrets and variables > Actions**:

- `AWS_ACCESS_KEY_ID`: the IAM user's access key ID.
- `AWS_SECRET_ACCESS_KEY`: the IAM user's secret access key.

Never put either value in `local.tf`, Terraform files, commits, or workflow
text. Access keys are long-lived credentials; rotate them and restrict the IAM
user's permissions. Move to GitHub OIDC later to remove stored AWS secrets.

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
