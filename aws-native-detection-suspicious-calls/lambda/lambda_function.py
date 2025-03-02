import json
import boto3
import gzip
import os
import logging

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients outside the handler to reuse them across invocations
sns_client = boto3.client('sns')
s3_client = boto3.client('s3')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
    
    try:
        # Get the bucket and object key from the S3 event
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        # Get the object from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read()
        
        # Decompress if needed
        try:
            content = gzip.decompress(content).decode('utf-8')
        except OSError:
            content = content.decode('utf-8')
        
        # Parse the CloudTrail log
        cloudtrail_event = json.loads(content)
        
        # Check if the event is a CreateUser event
        create_user_events = [record for record in cloudtrail_event['Records'] if record['eventName'] == 'CreateUser']
        
        for record in create_user_events:
            # Trigger an SNS notification
            message = f"CreateUser event detected: {json.dumps(record, indent=2)}"
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=message,
                Subject='CreateUser Event Notification'
            )
            logger.info("CreateUser event notification sent.")
        
    except Exception as e:
        logger.error("Error processing event: %s", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps('Error processing event')
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps('Lambda function executed successfully!')
    }