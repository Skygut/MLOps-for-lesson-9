#!/bin/bash

# Update system packages
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Python 3 and pip
yum install -y python3 python3-pip

# Install useful tools
yum install -y git htop tree vim

# Create a simple web server for testing
cat > /home/ec2-user/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${project_name} Server</title>
</head>
<body>
    <h1>Welcome to ${project_name}</h1>
    <p>This server is running on AWS EC2</p>
    <p>Instance deployed with Terraform</p>
</body>
</html>
EOF

# Start a simple Python web server
cd /home/ec2-user
nohup python3 -m http.server 80 > /var/log/webserver.log 2>&1 &

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log