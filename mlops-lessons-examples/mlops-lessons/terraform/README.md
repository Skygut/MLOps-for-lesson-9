# MLOps Lessons Terraform Infrastructure

This Terraform configuration creates AWS infrastructure suitable for a trial AWS account, including VPC networking and a simple EC2 compute instance.

## Architecture

The infrastructure includes:

### VPC (vpc.tf)
- Uses terraform-aws-modules/vpc/aws module for best practices
- VPC with configurable CIDR block (default: 10.0.0.0/16)
- Multi-AZ deployment with public and private subnets
- Internet Gateway for internet access
- Optional NAT Gateway for private subnet internet access (disabled by default for cost savings)
- Automatic route table creation and associations
- Security group with HTTP, HTTPS, and SSH access

### Compute (compute.tf)
- EC2 instance (t2.micro - free tier eligible)
- Key pair for SSH access
- Optional Elastic IP
- User data script for initial setup
- Encrypted root volume

### State Management (main.tf)
- S3 bucket for Terraform state
- Versioning enabled
- Public access blocked
- Encryption configuration (commented out for trial accounts)

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (version 0.12+)
3. SSH key pair generated

## Quick Start

1. **Generate SSH key pair:**
   ```bash
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/mlops-lessons
   ```

2. **Copy and configure variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   # This will download the VPC module and other providers
   ```

4. **Plan deployment:**
   ```bash
   terraform plan
   ```

5. **Apply configuration:**
   ```bash
   terraform apply
   ```

6. **SSH to instance:**
   ```bash
   # Use the SSH command from terraform output
   terraform output ssh_connection_command
   ```

## Configuration

### Required Variables

- `public_key`: Your SSH public key content
- `bucket_name`: Globally unique S3 bucket name

### Optional Variables

See `variables.tf` for all available options. Key settings for trial accounts:

- `instance_type`: "t2.micro" (free tier)
- `root_volume_size`: 8 GB (within free tier limits)
- `create_eip`: false (to avoid charges)
- `enable_nat_gateway`: false (to avoid NAT Gateway charges)
- `availability_zones`: Multi-AZ for high availability
- `allowed_ssh_cidr`: Restrict to your IP for security

## Trial Account Considerations

This configuration is optimized for AWS trial accounts:

- Uses t2.micro instance (free tier eligible)
- 8GB root volume (free tier includes 30GB/month)
- No Elastic IP by default (charges apply when not attached)
- No NAT Gateway by default (additional charges)
- Multi-AZ VPC setup for scalability
- Terraform VPC module for best practices

## Security Notes

For production use:
- Restrict SSH access (`allowed_ssh_cidr`) to specific IP ranges
- Enable S3 encryption
- Use private subnets for application servers
- Implement proper IAM roles and policies
- Enable CloudTrail and monitoring

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Outputs

After successful deployment, you'll get:
- VPC ID and CIDR block
- Public and private subnet IDs
- Internet Gateway and NAT Gateway IDs (if enabled)
- Instance public IP and DNS
- SSH connection command
- Security group ID

## Troubleshooting

1. **SSH Issues**: Ensure your private key has correct permissions (chmod 600)
2. **S3 Bucket Exists**: Choose a globally unique bucket name
3. **AMI Not Found**: Update `instance_ami` for your region
4. **Region Mismatch**: Ensure all resources use the same region

## File Structure

- `vpc.tf` - VPC, subnets, security groups
- `compute.tf` - EC2 instance and related resources
- `main.tf` - S3 state bucket
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values
- `terraform.tf` - Provider configuration
- `user_data.sh` - Instance initialization script
- `terraform.tfvars.example` - Example configuration