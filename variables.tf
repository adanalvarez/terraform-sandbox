variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name tag for the main VPC"
  type        = string
}

variable "subnet_az1_cidr" {
  description = "CIDR block for the subnet in AZ1"
  type        = string
}

variable "subnet_az1_name" {
  description = "Name tag for the subnet in AZ1"
  type        = string
}

variable "subnet_az2_cidr" {
  description = "CIDR block for the subnet in AZ2"
  type        = string
}

variable "subnet_az2_name" {
  description = "Name tag for the subnet in AZ2"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "s3_trail_bucket_name" {
  description = "Name of the S3 bucket for the trail"
  type        = string
}

variable "ssm_instance_name" {
  description = "Name tag for the EC2 instance that uses SSM"
  type        = string
}
