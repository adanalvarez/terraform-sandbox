# AWS User Creation Alerting - Terraform Configuration

## Overview

This Terraform configuration sets up an AWS-native alerting system to detect and notify on IAM user creation events. The setup utilizes multiple AWS services to explore different alerting methods, including EventBridge, CloudTrail, CloudWatch, S3, Lambda, and SNS.

> **Note:** AWS costs may apply for logging, data transfer, and Lambda execution.


## Components

- **SNS**: Sends email notifications for user creation events.
- **CloudTrail & S3**: Captures API activity logs and stores them for analysis.
- **CloudWatch Logs & Metric Filters**: Monitors logs and triggers alerts based on defined patterns.
- **Lambda Function**: Processes S3 events and sends alerts.
- **EventBridge**: Triggers alerts in near real-time.

## Alerting Methods

This setup enables three different approaches to alert on IAM user creation:

1. **EventBridge → SNS → Email** (Fastest and simplest)
2. **CloudTrail → S3 → Lambda → SNS → Email** (More customizable with log storage)
3. **CloudTrail → CloudWatch → MetricFilter → MetricAlert → SNS → Email** (Good for structured alerting but limited detail in notifications)

## Deployment

### Prerequisites

- Terraform installed
- AWS credentials configured
- An email address to receive SNS notifications

### Steps to Deploy

1. Clone this repository and navigate to the directory.
2. Initialize Terraform:
   ```sh
   terraform init
   ```
3. Update terraform.tfvars.json.example with you email and rename it to terraform.tfvars.json
4. Apply the configuration:
   ```sh
   terraform apply -auto-approve
   ```
5. Confirm the SNS email subscription by clicking the confirmation link sent to your email.

Once the deployment is done, you can test the notifications by creating a new IAM user.

The creation of a new IAM user should trigger 3 notifications, one per each scenario.

## Cleanup

To remove all deployed resources, run:

```sh
terraform destroy -auto-approve
```

This code was used for the blog post: https://medium.com/@adan.alvarez/diy-evaluating-aws-native-approaches-for-detecting-suspicious-api-calls-c6e05de97a49
