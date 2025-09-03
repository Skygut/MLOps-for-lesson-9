variable "region" {
    default = "eu-west-2"
    description = "The AWS region to deploy resources in."
    type = string
}

variable "bucket_name" {
    default = "mlops-tf-state"
    description = "The name of the S3 bucket for Terraform state."
    type = string
}

variable "tags" {
    description = "A map of tags to assign to the resources."
    type = map(string)
    default = {
        Environment = "Dev"
    }
}

variable "force_destroy" {
    description = "Whether to force destroy the S3 bucket even if it contains objects."
    type = bool
    default = true
}

# VPC Variables
variable "project_name" {
    description = "Name of the project, used for resource naming"
    type = string
    default = "mlops-lessons"
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "availability_zones" {
    description = "List of availability zones"
    type = list(string)
    default = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
    description = "CIDR blocks for public subnets"
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
    description = "CIDR blocks for private subnets"
    type = list(string)
    default = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "enable_nat_gateway" {
    description = "Enable NAT Gateway for private subnets"
    type = bool
    default = false  # Disabled for trial account to save costs
}

variable "allowed_ssh_cidr" {
    description = "CIDR block allowed to SSH to instances"
    type = string
    default = "0.0.0.0/0"  # For trial account - restrict this in production
}

# Compute Variables (commented out since compute resources are disabled)
# variable "instance_type" {
#     description = "EC2 instance type"
#     type = string
#     default = "t2.micro"  # Free tier eligible
# }

# variable "instance_ami" {
#     description = "AMI ID for the EC2 instance"
#     type = string
#     default = "ami-0c02fb55956c7d316"  # Amazon Linux 2 in us-west-2
# }

# variable "public_key" {
#     description = "Public key for EC2 key pair"
#     type = string
#     default = ""  # Should be provided during terraform apply
# }

# variable "root_volume_size" {
#     description = "Size of the root volume in GB"
#     type = number
#     default = 8  # Free tier includes 30GB per month
# }

# variable "create_eip" {
#     description = "Whether to create an Elastic IP for the instance"
#     type = bool
#     default = false  # EIPs have charges if not attached
# }