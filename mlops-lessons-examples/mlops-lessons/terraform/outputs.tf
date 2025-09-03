output "bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

# # Compute Outputs
# output "instance_id" {
#   description = "ID of the EC2 instance"
#   value       = aws_instance.web.id
# }

# output "instance_public_ip" {
#   description = "Public IP address of the EC2 instance"
#   value       = aws_instance.web.public_ip
# }

# output "instance_public_dns" {
#   description = "Public DNS name of the EC2 instance"
#   value       = aws_instance.web.public_dns
# }

# output "elastic_ip" {
#   description = "Elastic IP address (if created)"
#   value       = var.create_eip ? aws_eip.web[0].public_ip : null
# }

# output "key_pair_name" {
#   description = "Name of the key pair"
#   value       = aws_key_pair.main.key_name
# }

# output "ssh_connection_command" {
#   description = "Command to SSH into the instance"
#   value       = "ssh -i ~/.ssh/${aws_key_pair.main.key_name}.pem ec2-user@${aws_instance.web.public_ip}"
# }