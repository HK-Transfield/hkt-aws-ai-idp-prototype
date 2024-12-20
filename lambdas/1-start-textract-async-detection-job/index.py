__author__ = "HK Transfield"
__status__ = "Development"
__license__  = "GPL-3.0"

import boto3
import os

region = boto3.session.Session().region_name

def lambda_handler(event, context):
    """
    Starts a Textract asynchronous job when triggered by an upload to an S3 bucket.

    args:
        event (obj): the trigger for the function
        context (obj): methods and props about the invocation, function, and exec env
    """
    textract = boto3.client('textract', region_name=region)

    # Extract event info
    s3_bucket = event['Records'][0]['s3']['bucket']['name']
    document = event['Records'][0]['s3']['object']['key']

    # env variables
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']
    role_arn = os.environ['SNS_ROLE_ARN']

    try:
        response = textract.start_document_text_detection(
            DocumentLocation={
                'S3Object': {
                    'Bucket': s3_bucket,
                    'Name': document
                }
            },
            NotificationChannel={
                'SNSTopicArn': sns_topic_arn,
                'RoleArn': role_arn
            }
        )

        return {
            'statusCode': 200,
            'JobId': response['JobId']
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'Error': str(e)
        }