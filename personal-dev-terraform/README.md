# Personal Dev Terraform — EC2 Free Tier

Terraform configuration to deploy the Jenkins MFE stack on an **AWS EC2 t2.micro** (free tier eligible).

## What Gets Provisioned

| Resource | Details |
|----------|---------|
| EC2 Instance | `t2.micro`, Amazon Linux 2023, 30 GB gp3 (encrypted) |
| IAM Role | SSM Session Manager + CloudWatch Agent policies |
| Security Group | HTTP (80), HTTPS (443) — no SSH port exposed |
| User Data | Auto-installs Docker, Compose, clones repo, starts stack |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- AWS CLI configured (`aws configure`) or env vars (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) for AWS CLI
- A Cloudflare Tunnel token

## Quick Start

```bash
cd personal-dev-terraform

# 1. Copy and fill in your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Initialize Terraform
terraform init

# 3. Preview the plan
terraform plan

# 4. Deploy
terraform apply

# 5. Connect via SSM Session Manager
aws ssm start-session --target $(terraform output -raw instance_id)
```

## Post-Deploy Verification

```bash
# Connect to the instance
aws ssm start-session --target <instance-id>

# Check cloud-init / userdata progress
sudo tail -f /var/log/userdata.log

# Verify containers are running
cd ~/simple-jenkins-job
docker compose ps

# Check logs
docker logs -f nginx
docker logs -f jenkins
```

## Tear Down

```bash
terraform destroy
```

## Free Tier Notes

- **t2.micro**: 750 hours/month free for 12 months
- **30 GB gp3 EBS**: within the 30 GB free tier allowance
- **Data transfer**: 100 GB/month outbound free (first 12 months)
- **Elastic IP**: not provisioned (uses the default public IP — free while instance is running)
- After 12 months, estimated cost is ~$8.50/month (see costing in the project README)

## Security

- No SSH port (22) exposed — access via SSM Session Manager only
- `terraform.tfvars` is git-ignored (contains secrets)
- All traffic routes through Cloudflare Tunnel (no direct Jenkins access from the internet)
- EBS volume is encrypted at rest
- The Cloudflare Tunnel token is injected via user data, not stored in Terraform state long-term
