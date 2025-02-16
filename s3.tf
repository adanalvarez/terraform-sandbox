# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.main_rt.id]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "work_load_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name = var.s3_bucket_name
  }
}