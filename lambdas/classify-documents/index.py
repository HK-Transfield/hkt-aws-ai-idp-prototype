import boto3
import json
import os
from datetime import datetime

# Initialize AWS clients
s3 = boto3.client('s3')
textract = boto3.client('textract')
bedrock = boto3.client('bedrock-runtime')
sqs = boto3.client('sqs')

RESULT_BUCKET = os.environ['RESULT_BUCKET']

def lambda_handler(event, context):
    for record in event['Records']:
        try:
            # Extract SQS message body
            message_body = json.loads(record['body'])
            job_id = message_body.get("JobId")
            document_name = message_body.get("DocumentName")
            
            print(f"Processing Textract JobId: {job_id} for document: {document_name}")

            # Step 1: Retrieve Textract OCR results
            textract_result = textract.get_document_text_detection(JobId=job_id)
            ocr_text = extract_text_from_textract(textract_result)

            # Step 2: Invoke Amazon Bedrock for classification
            classification_result = classify_with_bedrock(ocr_text)

            # Step 3: Save OCR text and classification result to S3
            save_to_s3(document_name, ocr_text, classification_result)

            print(f"Successfully processed JobId: {job_id}")

        except Exception as e:
            print(f"Error processing record: {e}")
            continue

def extract_text_from_textract(textract_result):
    """Extract raw text from Textract OCR result."""
    pages = textract_result.get("Blocks", [])
    text_lines = [block['Text'] for block in pages if block['BlockType'] == "LINE"]
    return "\n".join(text_lines)

def classify_with_bedrock(ocr_text):
    """Call Amazon Bedrock to classify the OCR text."""
    prompt = f"""Classify the following document text into categories like 'Invoice', 'Receipt', 'Report', etc.:
    {ocr_text}
    """
    response = bedrock.invoke_model(
        modelId="anthropic.claude-v2",
        body=json.dumps({"prompt": prompt, "max_tokens": 500})
    )
    result = json.loads(response['body'])
    return result['completion']

def save_to_s3(document_name, ocr_text, classification_result):
    """Save OCR text and classification result to S3."""
    timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
    ocr_key = f"results/{document_name}_ocr_{timestamp}.txt"
    result_key = f"results/{document_name}_classification_{timestamp}.json"

    # Save OCR text
    s3.put_object(
        Bucket=RESULT_BUCKET,
        Key=ocr_key,
        Body=ocr_text,
        ContentType="text/plain"
    )

    # Save classification result
    s3.put_object(
        Bucket=RESULT_BUCKET,
        Key=result_key,
        Body=json.dumps({"classification_result": classification_result}, indent=2),
        ContentType="application/json"
    )