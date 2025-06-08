import json
import boto3
import uuid

def lambda_handler(event, context):
    iam = boto3.client('iam')
    username = f"user-{uuid.uuid4().hex[:8]}"

    try:
        iam.create_user(UserName=username)
        return {
            "statusCode": 200,
            "body": json.dumps({"username": username})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
