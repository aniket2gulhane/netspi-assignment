# Create a VPC with the specified CIDR block
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create an Internet Gateway for the VPC
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create a route table for the VPC
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "my_route_table_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a subnet within the VPC
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet_cidr
}

# Create a security group to allow SSH access
resource "aws_security_group" "allow_ssh" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an S3 bucket with private access
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name

  acl = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name   = "s3_access_policy"
  role   = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Create an EFS file system
resource "aws_efs_file_system" "my_efs" {}

# Create a mount target for the EFS file system in the subnet
resource "aws_efs_mount_target" "my_efs_mount" {
  file_system_id = aws_efs_file_system.my_efs.id
  subnet_id      = aws_subnet.my_subnet.id
  security_groups = [aws_security_group.allow_ssh.id]
}

# Create an EC2 instance with SSH access and mount the EFS volume at /data/test
resource "aws_instance" "my_instance" {
  ami           = "ami-0034529272b0a8509" # Amazon Linux 2 AMI
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.my_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  iam_instance_profile  = aws_iam_instance_profile.ec2_instance_profile.name


  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y amazon-efs-utils
              sudo pip3 install botocore
              if [ $? -eq 0 ]; then
                echo "amazon-efs-utils installed successfully"
              else
                echo "Failed to install amazon-efs-utils" >&2
                exit 1
              fi
              mkdir -p /data/test
              sudo mount -t efs ${aws_efs_file_system.my_efs.id}:/ /data/test
              # Write a test file to the S3 bucket
              echo "This is a test file" > /tmp/testfile.txt
              aws s3 cp /tmp/testfile.txt s3://${var.bucket_name}/testfile.txt
              EOF

  associate_public_ip_address = true
}

# Associate the Elastic IP with the EC2 instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.my_instance.id
  allocation_id = var.eip_allocation_id
}