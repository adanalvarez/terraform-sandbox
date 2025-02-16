resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "ssm_endpoint_sg"
  description = "Security group for SSM VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssm_endpoint_sg"
  }
}

# SSM API Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_az1.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ssm-endpoint"
  }
}

# EC2 Messages Endpoint (required for SSM)
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_az1.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ec2messages-endpoint"
  }
}

# SSM Messages Endpoint (required for Session Manager)
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.subnet_az1.id]
  security_group_ids  = [aws_security_group.ssm_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "ssmmessages-endpoint"
  }
}
