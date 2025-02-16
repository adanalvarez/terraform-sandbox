output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_az1_id" {
  value = aws_subnet.subnet_az1.id
}

output "ssm_instance_id" {
  value = aws_instance.ssm_instance.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.work_load_bucket.bucket
}
