__author__ = "HK Transfield"
__status__ = "Development"
__license__  = "GPL-3.0"

import boto3
import os
import json

s3 = boto3.client('s3')

def lambda_handler(event, _):
    # Get the bucket and object key from the event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']

    # Environment variables
    target_bucket = os.environ['TARGET_BUCKET']
    classified_docs_obj_key = os.environ['CLASSIFIED_DOCS_OBJ_KEY']
    
    try:
        # Read the document from the source S3 bucket
        response = s3.get_object(Bucket=source_bucket, Key=object_key)
        document_content = response['Body'].read().decode('utf-8')
        
        # Get classification results from the S3 bucket
        classification_response = s3.get_object(Bucket=source_bucket, Key=classified_docs_obj_key)
        classification = classification_response['Body'].read().decode('utf-8')
        
        # Create enrichment instructions based on classification
        enrichment_instructions = create_enrichment_instructions(classification)
        
        # Call Bedrock for enrichment
        enriched_content = invoke_bedrock_for_enrichment(document_content, enrichment_instructions)
        
        # Save the enriched document to the target S3 bucket
        enriched_object_key = f"enriched/{object_key}"
        s3.put_object(Bucket=target_bucket, Key=enriched_object_key, Body=enriched_content)
        
        return {
            'statusCode': 200,
            'body': json.dumps('Document processed successfully')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error processing document: {str(e)}')
        }

def create_enrichment_instructions(classification):
    # Implement your logic to create enrichment instructions based on classification
    return f"Enrichment instructions for {classification}"

def invoke_bedrock_for_enrichment(document_content, enrichment_instructions):
    # Implement your logic to call Bedrock for enrichment
    return f"Enriched content based on {document_content} with {enrichment_instructions}"

def format_prompt(document_content):
    return f"""
    Given the document

    <document>{document_content}</document>

    Give me a 50 word summary of this document that can be shown alongside search results. 

    Return only the summary text with no preamble. 
    """