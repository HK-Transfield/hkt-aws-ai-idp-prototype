__author__ = "HK Transfield"
__status__ = "Development"
__license__  = "GPL-3.0"

import json
import boto3
import os

region = boto3.session.Session().region_name
s3 = boto3.client('s3')
sqs = boto3.client('sqs')
bedrock = boto3.client('bedrock')

def lambda_handler(event, context):
    try:
        # Environment variables
        output_bucket = os.environ['OUTPUT_BUCKET']
        output_object_key = os.environ['OUTPUT_OBJECT_KEY']
        bedrock_model_id = os.environ['BEDROCK_MODEL_ID']

        # Get the message from the SQS queue
        for message in event['Records']:
            # Extract the S3 bucket and key from the message
            s3_bucket = message['s3']['bucket']['name']
            s3_key = message['s3']['object']['key']

            # Get the document from S3
            document = s3.get_object(Bucket=s3_bucket, Key=s3_key)
            document_content = document['Body'].read()

            # Call Bedrock with classification prompt
            prompt = format_prompt(document_content)
            bedrock_response = bedrock.invoke_model(ModelId=bedrock_model_id, ContentType='application/json', Body=json.dumps({'prompt': prompt}))
            classification_result = json.loads(bedrock_response['Body'].read())

            # Save classification result to S3
            s3.put_object(Bucket=output_bucket, Key=f"{output_object_key}/{s3_key}.json", Body=json.dumps(classification_result))

            # Delete message from SQS
            sqs.delete_message(QueueUrl=message['eventSourceARN'], ReceiptHandle=record['receiptHandle'])
        return {
            'statusCode': 200,
            'body': json.dumps('Successfully classified the message')
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps('Error processing the message')
        }

def format_prompt(document_content):
    return f"""
    Given the document

    <document>{document_content}</document>

    classify the document into the following classes

    <classes>
    DRIVERS_LICENSE
    INSURANCE_ID
    RECEIPT
    BANK_STATEMENT
    W2
    MEETING_MINUTES
    </classes>



    return only the CLASS_NAME with no preamble or explanation. 
    """