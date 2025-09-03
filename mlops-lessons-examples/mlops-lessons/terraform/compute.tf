# # Key Pair for EC2 Instance
# resource "aws_key_pair" "main" {
#   key_name   = "${var.project_name}-keypair"
#   public_key = var.public_key

#   tags = merge(var.tags, {
#     Name = "${var.project_name}-keypair"
#   })
# }

# # EC2 Instance
# resource "aws_instance" "web" {
#   ami                    = var.instance_ami
#   instance_type          = var.instance_type
#   key_name               = aws_key_pair.main.key_name
#   vpc_security_group_ids = [aws_security_group.web.id]
#   subnet_id              = module.vpc.public_subnets[0]

#   user_data = base64encode(templatefile("${path.module}/user_data.sh", {
#     project_name = var.project_name
#   }))

#   root_block_device {
#     volume_type = "gp3"
#     volume_size = var.root_volume_size
#     encrypted   = true
    
#     tags = merge(var.tags, {
#       Name = "${var.project_name}-root-volume"
#     })
#   }

#   tags = merge(var.tags, {
#     Name = "${var.project_name}-web-server"
#     Type = "WebServer"
#   })

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # Elastic IP for the instance (optional, for static IP)
# resource "aws_eip" "web" {
#   count    = var.create_eip ? 1 : 0
#   instance = aws_instance.web.id
#   domain   = "vpc"

#   tags = merge(var.tags, {
#     Name = "${var.project_name}-eip"
#   })

#   depends_on = [module.vpc]
# }