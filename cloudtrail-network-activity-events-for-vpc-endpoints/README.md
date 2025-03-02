# CloudTrail Network Activity Events for VPC Endpoints

This Terraform configuration deploys an AWS environment to test the new CloudTrail network activity events feature for VPC endpoints. The deployment includes:

- VPC & Private Subnet: A VPC with a dedicated private subnet.
- EC2 Instance: An instance launched within the private subnet.
- S3 VPC Endpoint: Allows the EC2 instance to access S3 without traversing the public internet.
- SSM Endpoints: Enable secure management and access to the EC2 instance via AWS Systems Manager.
- CloudTrail: Configured to record network activity events related to VPC endpoints, as detailed in the AWS blog post.
  
## How to Deploy

Configure AWS CLI: Ensure your AWS CLI is configured with the necessary credentials and permissions.
Initialize Terraform:
```
terraform init
```
Review Variables: Modify the variables from terraform.tfvars.json.example and rename it to terraform.tfvars.json.

Plan the Deployment:
```
terraform plan
```
Apply the Configuration:
```
terraform apply
```
This will create all the resources required to test and explore the CloudTrail network activity events feature.

## Testing the Feature
- SSM Access: Use AWS Systems Manager to access the EC2 instance.
- CloudTrail Logs: Perform operations such as accessing the S3 from this account and other accounts and then check CloudTrail logs in the S3 to see the recorded network activity events.

## Cleanup
To destroy all resources created by this configuration:
```
terraform destroy
```


