__author__ = "HK Transfield"
__status__ = "Development"
__license__  = "GPL-3.0"

import json
import boto3
import os

sqs = boto3.client('sqs')
textract = boto3.client('textract')
bedrock = boto3.client('bedrock')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Read message from SQS
    for record in event['Records']:
        message = json.loads(record['body'])
        document_s3_bucket = message['Records'][0]['s3']['bucket']['name']
        document_s3_key = message['Records'][0]['s3']['object']['key']
        
        # Get document from S3
        document = s3.get_object(Bucket=document_s3_bucket, Key=document_s3_key)
        document_content = document['Body'].read()
        
        # Call Textract to read document text
        response = textract.detect_document_text(Document={'Bytes': document_content})
        raw_text = ' '.join([item['DetectedText'] for item in response['Blocks'] if item['BlockType'] == 'LINE'])
        
        # Call Bedrock with classification prompt
        prompt = f"Classify the following document text: {raw_text}"
        bedrock_response = bedrock.invoke_model(ModelId='your-model-id', ContentType='application/json', Body=json.dumps({'prompt': prompt}))
        classification_result = json.loads(bedrock_response['Body'].read())
        
        # Save raw text and classification result to S3
        s3.put_object(Bucket=os.environ['S3_BUCKET'], Key=f"raw_text/{document_s3_key}.txt", Body=raw_text)
        s3.put_object(Bucket=os.environ['S3_BUCKET'], Key=f"classification_result/{document_s3_key}.json", Body=json.dumps(classification_result))
        
        # Delete message from SQS
        sqs.delete_message(QueueUrl=message['eventSourceARN'], ReceiptHandle=record['receiptHandle'])

    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }