import boto3
import os

region = boto3.session.Session().region_name

def lambda_handler(event, context):
    """
    A Lambda function triggered when documents are uploaded
    to an S3 bucket.

    args:
        event (obj): the trigger for the function
        context (obj): methods and props about the invocation, function, and exec env
    """
    
    # AWS services
    s3 = boto3.resource('s3')
    textract = boto3.client('textract', region_name=region)
    comprehend = boto3.client('comprehend', region_name=region)
    sns = boto3.client('sns')

    # events
    document = event['document']

    # env variables
    s3_bucket = os.environ['BUCKET_NAME']
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']
    role_arn = os.environ['TEXTRACT_ROLE_ARN']

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
