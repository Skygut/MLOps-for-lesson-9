# Simple VPC Module Configuration (without flow logs to avoid deprecation warnings)
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "= 5.21.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # Internet Gateway
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = false
  
  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Public subnet configuration
  map_public_ip_on_launch = true

  # Completely disable VPC Flow Logs and related resources
  enable_flow_log                      = false
  create_flow_log_cloudwatch_iam_role  = false
  create_flow_log_cloudwatch_log_group = false

  # Tags
  tags = var.tags

  public_subnet_tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "Public"
  }

  private_subnet_tags = {
    Name = "${var.project_name}-private-subnet"
    Type = "Private"
  }

  igw_tags = {
    Name = "${var.project_name}-igw"
  }

  nat_gateway_tags = {
    Name = "${var.project_name}-nat"
  }

  public_route_table_tags = {
    Name = "${var.project_name}-public-rt"
  }

  private_route_table_tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Security Group for Web Traffic
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-web-sg"
  })
}