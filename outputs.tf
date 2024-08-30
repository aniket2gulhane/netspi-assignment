output "bucket_name" {
  value = aws_s3_bucket.my_bucket.bucket
}

output "efs_id" {
  value = aws_efs_file_system.my_efs.id
}

output "instance_id" {
  value = aws_instance.my_instance.id
}

output "security_group_id" {
  value = aws_security_group.allow_ssh.id
}

output "subnet_id" {
  value = aws_subnet.my_subnet.id
}