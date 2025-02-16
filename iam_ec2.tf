# IAM Role for EC2
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "ec2_s3_policy"
  description = "Policy for EC2 to read/write to the S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowListBucket",
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = aws_s3_bucket.work_load_bucket.arn
      },
      {
        Sid    = "AllowObjectActions",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "${aws_s3_bucket.work_load_bucket.arn}/*"
      }
    ]
  })
}

# Attach S3 Policy to the Role
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# Attach AWS Managed Policy for SSM (allows the instance to be managed via Systems Manager)
resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_s3_role.name
}

# Data lookup for the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
}

# Create a very small EC2 instance (t3.nano)
resource "aws_instance" "ssm_instance" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t3.nano"
  subnet_id            = aws_subnet.subnet_az1.id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = var.ssm_instance_name
  }
}
