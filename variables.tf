variable "region" {
  description = "The AWS region to deploy to"
  default     = "us-west-2"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  default     = "my-private-bucket"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "The EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the SSH key pair"
  default     = "my-key-pair"
}

variable "eip_allocation_id" {
  description = "The allocation ID of the Elastic IP"
  default     = "eipalloc-xxxxxxxx"
}