# Data account id
data "aws_caller_identity" "current" {}

provider "aws" {
    region = var.aws_region
}

# SNS Topic and Subscription
resource "aws_sns_topic" "user_creation_topic" {
    name = "user-creation-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
    topic_arn = aws_sns_topic.user_creation_topic.arn
    protocol  = "email"
    endpoint  = var.email_endpoint
}

# CloudTrail and S3 Bucket
resource "aws_s3_bucket" "trail_logs" {
    bucket = "cloudtrail-user-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_policy" "trail_logs_policy" {
    bucket = aws_s3_bucket.trail_logs.bucket
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect    = "Allow"
                Principal = {
                    Service = "cloudtrail.amazonaws.com"
                }
                Action    = "s3:GetBucketAcl"
                Resource  = aws_s3_bucket.trail_logs.arn
            },
            {
                Effect    = "Allow"
                Principal = {
                    Service = "cloudtrail.amazonaws.com"
                }
                Action    = "s3:PutObject"
                Resource  = "${aws_s3_bucket.trail_logs.arn}/*"
            }
        ]
    })
}

resource "aws_cloudtrail" "user_trail" {
    name                          = "user-trail"
    s3_bucket_name                = aws_s3_bucket.trail_logs.bucket
    include_global_service_events = true
    is_multi_region_trail         = true

    cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.user_log_group.arn}:*"
    cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_role.arn
}

# IAM Role and Policy for CloudTrail
resource "aws_iam_role" "cloudtrail_role" {
    name = "cloudtrail-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect    = "Allow"
                Principal = {
                    Service = "cloudtrail.amazonaws.com"
                }
                Action    = "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_policy" "cloudtrail_policy" {
    name        = "cloudtrail-policy"
    description = "Policy for CloudTrail"
    policy      = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect   = "Allow"
                Action   = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_policy_attachment" {
    policy_arn = aws_iam_policy.cloudtrail_policy.arn
    role       = aws_iam_role.cloudtrail_role.name
}

# CloudWatch Log Group and Stream
resource "aws_cloudwatch_log_group" "user_log_group" {
    name = "cloudtrail-user-logs"
}

resource "aws_cloudwatch_log_stream" "user_log_stream" {
    name           = "user-log-stream"
    log_group_name = aws_cloudwatch_log_group.user_log_group.name
}

# CloudWatch Metric Filter and Alarm
resource "aws_cloudwatch_log_metric_filter" "user_creation_filter" {
    name           = "UserCreationFilter"
    log_group_name = aws_cloudwatch_log_group.user_log_group.name
    pattern = "{$.eventName = CreateUser}"
    metric_transformation {
        name      = "UserCreationMetric"
        namespace = "CloudTrailMetrics"
        value     = "1"
    }
}

resource "aws_cloudwatch_metric_alarm" "user_creation_alarm" {
    alarm_name          = "UserCreationAlarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "1"
    metric_name         = "UserCreationMetric"
    namespace           = "CloudTrailMetrics"
    period              = "60"
    statistic           = "Sum"
    threshold           = "1"
    alarm_actions       = [aws_sns_topic.user_creation_topic.arn]
}

# Lambda Function and S3 Trigger
data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "${path.module}/lambda"
    output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "s3_trigger_lambda" {
    function_name    = "s3-user-creation-alert"
    runtime          = "python3.10"
    handler          = "lambda_function.lambda_handler"
    role             = aws_iam_role.lambda_exec.arn
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    filename         = data.archive_file.lambda_zip.output_path
    environment {
        variables = {
            SNS_TOPIC_ARN = aws_sns_topic.user_creation_topic.arn
        }
    }
}

resource "aws_s3_bucket_notification" "s3_notification" {
    bucket = aws_s3_bucket.trail_logs.bucket

    lambda_function {
        lambda_function_arn = aws_lambda_function.s3_trigger_lambda.arn
        events              = ["s3:ObjectCreated:*"]
    }
}

# IAM Role and Policy for Lambda
resource "aws_iam_role" "lambda_exec" {
    name = "lambda_exec_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
                Effect = "Allow"
                Sid    = ""
            }
        ]
    })
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
    name   = "lambda_exec_policy"
    role   = aws_iam_role.lambda_exec.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect   = "Allow"
                Action   = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Resource = "*"
            },
            {
                Effect   = "Allow"
                Action   = "s3:GetObject"
                Resource = "${aws_s3_bucket.trail_logs.arn}/*"
            },
            {
                Effect   = "Allow"
                Action   = "sns:Publish"
                Resource = aws_sns_topic.user_creation_topic.arn
            }
        ]
    })
}

resource "aws_lambda_permission" "s3_trigger_lambda" {
    statement_id  = "AllowExecutionFromS3Bucket"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.s3_trigger_lambda.function_name
    principal     = "s3.amazonaws.com"
    source_arn    = aws_s3_bucket.trail_logs.arn
}

# EventBridge Rule (default event bus) and Target
resource "aws_cloudwatch_event_rule" "user_creation_rule" {
    name        = "UserCreationRule"
    description = "Trigger on user creation"

    event_pattern = jsonencode({
        source = ["aws.iam"]
        "detail-type" = ["AWS API Call via CloudTrail"]
        detail = {
            eventSource = ["iam.amazonaws.com"]
            eventName   = ["CreateUser"]
        }
    })
}

# Eventbridge rule to detect ses ListIdentities
resource "aws_cloudwatch_event_rule" "ses_list_identities_rule" {
    name        = "SESListIdentitiesRule"
    description = "Trigger on SES ListIdentities"
    state       = "ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS"

    event_pattern = jsonencode({
        source = ["aws.ses"]
        detail-type = ["AWS API Call via CloudTrail"]
        detail = {
            eventSource = ["ses.amazonaws.com"]
            eventName   = ["ListIdentities"]
        }
    })
}

resource "aws_cloudwatch_event_target" "ses_list_rule_sns_target" {
    rule      = aws_cloudwatch_event_rule.ses_list_identities_rule.name
    target_id = "SendToSNS"
    arn       = aws_sns_topic.user_creation_topic.arn
}

resource "aws_cloudwatch_event_target" "sns_target" {
    rule      = aws_cloudwatch_event_rule.user_creation_rule.name
    target_id = "SendToSNS"
    arn       = aws_sns_topic.user_creation_topic.arn
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "lambda.amazonaws.com", "logs.amazonaws.com"]
    }

    resources = [aws_sns_topic.user_creation_topic.arn]
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.user_creation_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}