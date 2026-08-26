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

## EBS volume and mount

The main Terraform configuration creates one encrypted 30 GB `gp3` EBS volume
in `ap-south-1a` and attaches it to the existing public EC2 instance. An AWS
Systems Manager command formats a new volume as XFS, mounts it at `/data`, and
adds it to `/etc/fstab` so it is mounted again after a reboot. No AWS access
keys are stored in GitHub.

Follow these steps:

1. Run the bootstrap Terraform once and add `github_actions_role_arn` as the
	GitHub repository variable `AWS_ROLE_ARN`.
2. Push a change under `main/` to the `main` branch.
3. Open the repository's **Actions** tab and wait for **Terraform Plan & Apply**
	to finish successfully.
4. In AWS Console, open **EC2 > Volumes** and confirm the 30 GiB volume is
	`In-use` and attached to the public instance.
5. In **Systems Manager > Fleet Manager**, confirm the public instance is
	`Managed`. SSM must be connected for Terraform to run the mount command.
6. On the instance, confirm `/data` is mounted with `df -h /data`.

If the instance is not `Managed`, install/start the SSM Agent and make sure its
EC2 instance profile has `AmazonSSMManagedInstanceCore`. This project adds that
policy to the existing EC2 role. The instance also needs outbound internet
access or VPC endpoints for Systems Manager.

To verify the disk from an SSM session, run:

```bash
lsblk
df -h /data
mountpoint /data
```

Do not run `mkfs` manually on a volume that contains data because formatting
erases the data.

## Local run

```powershell
cd main
terraform init
terraform plan
terraform apply
```

To avoid charges, run `terraform destroy` from `main`. The bootstrap bucket has
`prevent_destroy` enabled and must be removed separately if required.
