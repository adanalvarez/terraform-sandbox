data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "networktrail" {
  bucket        = var.s3_trail_bucket_name
  force_destroy = true

  tags = {
    Name = "networktrail"
  }
}

resource "aws_s3_bucket_policy" "networktrail_policy" {
  bucket = aws_s3_bucket.networktrail.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck20150319"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${aws_s3_bucket.networktrail.id}"
      },
      {
        Sid       = "AWSCloudTrailWrite20150319"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.networktrail.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "networktrail" {
  name                          = "networktrail"
  s3_bucket_name                = aws_s3_bucket.networktrail.bucket
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_logging                = true

  advanced_event_selector {
    name = "NetworkActivityEventSelector"

    field_selector {
      field  = "eventCategory"
      equals = ["NetworkActivity"]
    }

    field_selector {
      field  = "eventSource"
      equals = ["s3.amazonaws.com"]
    }
  }
}