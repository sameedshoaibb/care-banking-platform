# Terraform

Creates cloud infrastructure on Azure (VM, networking, security, monitoring).

## What Gets Created

- **Ubuntu VM** - Standard_D4ls_v5 in Azure UK West region
- **Virtual Network** - 10.0.0.0/16 with configured subnet
- **Security Rules** - SSH, Jenkins, Nginx, ArgoCD, GitHub webhooks
- **Monitoring** - CPU alerts when usage exceeds 80%
- **Public IP** - Static IP address for VM access

## Quick Start

**Step 1: Add Azure Credentials**
Edit `secrets.tfvars` with your Azure details:
```
subscription_id = "your-id"
tenant_id       = "your-id"
client_id       = "your-id"
client_secret   = "your-secret"
location        = "UK West"
infra_cidr      = "10.0.1.0/24"
```

**Step 2: Initialize Terraform**
```bash
terraform init
```

**Step 3: Review Changes**
```bash
terraform plan -var-file=secrets.tfvars
```

**Step 4: Create Infrastructure**
```bash
terraform apply -var-file=secrets.tfvars -auto-approve
```

Takes about 5-10 minutes.

## After Deployment

Get your VM details:
```bash
terraform output
```

You'll have your VM's public IP and admin credentials. Use these in the Ansible playbook next.

## Common Commands

```bash
terraform plan -var-file=secrets.tfvars    # Preview changes
terraform apply -var-file=secrets.tfvars   # Create infrastructure
terraform destroy -var-file=secrets.tfvars # Delete everything
terraform output                            # Show VM details
```

**Need to change location?**
Edit `location` in `secrets.tfvars` or `variables.tf` (default: UK West)

**Want to see what will change?**
Run `terraform plan -var-file=secrets.tfvars` before applying anything.
