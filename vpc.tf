resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "subnet_az1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_az1_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = var.subnet_az1_name
  }
}

resource "aws_subnet" "subnet_az2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_az2_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = var.subnet_az2_name
  }
}

# Create a route table for the VPC (used by the S3 gateway endpoint)
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-rt"
  }
}

resource "aws_route_table_association" "subnet_association_az1" {
  subnet_id      = aws_subnet.subnet_az1.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_route_table_association" "subnet_association_az2" {
  subnet_id      = aws_subnet.subnet_az2.id
  route_table_id = aws_route_table.main_rt.id
}
