
import boto3
import json
import time
from botocore.exceptions import ClientError

# Initialize AWS clients
comprehend = boto3.client('comprehend')
textract = boto3.client('textract')
s3 = boto3.client('s3')
    
def lambda_handler(event, context):
    # Configuration variables
    training_bucket = 'XXXXXXXXXXXXXXXXXXXX'
    training_key = 'training-data.csv'
    input_bucket = 'XXXXXXXXXXXXXXXXX'
    input_key = event['document_key']
    classifier_name = 'my-custom-classifier'
    endpoint_name = 'my-classifier-endpoint'
    
    try:
        # Step 1: Train the custom classifier
        response = comprehend.create_document_classifier(
            DocumentClassifierName=classifier_name,
            DataAccessRoleArn='arn:aws:iam::YOUR_ACCOUNT_ID:role/YourComprehendRole',
            InputDataConfig={
                'S3Uri': f's3://{training_bucket}/{training_key}',
                'LabelDelimiter': ','
            },
            LanguageCode='en'
        )
        
        classifier_arn = response['DocumentClassifierArn']
        
        # Wait for training to complete
        while True:
            status = comprehend.describe_document_classifier(
                DocumentClassifierArn=classifier_arn
            )['DocumentClassifierProperties']['Status']
            
            if status == 'TRAINED':
                break
            elif status == 'FAILED':
                raise Exception('Classifier training failed')
            time.sleep(60)
            
        # Step 2: Create real-time endpoint
        response = comprehend.create_endpoint(
            EndpointName=endpoint_name,
            ModelArn=classifier_arn,
            DesiredInferenceUnits=1
        )
        
        endpoint_arn = response['EndpointArn']
        
        # Wait for endpoint to be ready
        while True:
            status = comprehend.describe_endpoint(
                EndpointArn=endpoint_arn
            )['EndpointProperties']['Status']
            
            if status == 'IN_SERVICE':
                break
            elif status == 'FAILED':
                raise Exception('Endpoint creation failed')
            time.sleep(60)
            
        # Step 3: Extract text from document using Textract
        response = textract.detect_document_text(
            Document={
                'S3Object': {
                    'Bucket': input_bucket,
                    'Name': input_key
                }
            }
        )
        
        # Combine all text blocks
        extracted_text = ' '.join([block['Text'] for block in response['Blocks'] if block['BlockType'] == 'LINE'])
        
        # Step 4: Classify the extracted text
        response = comprehend.classify_document(
            Text=extracted_text,
            EndpointArn=endpoint_arn
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'classification': response['Classes'][0]['Name'],
                'confidence': response['Classes'][0]['Score']
            })
        }
        
    except ClientError as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }