output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "public_ec2_public_ip" {
  value = aws_instance.public_ec2.public_ip
}

output "ebs_volume_id" {
  value = aws_ebs_volume.data.id
}

output "ebs_mount_path" {
  value = "/data"
}

output "private_ec2_private_ip" {
  value = aws_instance.private_ec2.private_ip
}

output "app_bucket_name" {
  value = aws_s3_bucket.app_bucket.id
}
