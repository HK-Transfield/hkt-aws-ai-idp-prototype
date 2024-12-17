import boto3
import os

def lambda_handler(event, context):
    textract = boto3.client('textract')
    s3_bucket = os.environ['BUCKET_NAME']
    document = event['document']
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
