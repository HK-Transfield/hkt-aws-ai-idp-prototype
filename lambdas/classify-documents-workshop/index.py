import boto3
import botocore
import sagemaker
import os
import io
import datetime
import pandas as pd
from PIL import Image
from pathlib import Path
import multiprocessing as mp
from IPython.display import Image, display, HTML, JSON

# variables
data_bucket = sagemaker.Session().default_bucket()
region = boto3.session.Session().region_name

os.environ["BUCKET"] = data_bucket
os.environ["REGION"] = region
role = sagemaker.get_execution_role()

print(f"SageMaker role is: {role}\nDefault SageMaker Bucket: s3://{data_bucket}")

s3=boto3.client('s3')
textract = boto3.client('textract', region_name=region)
comprehend=boto3.client('comprehend', region_name=region)

def get_s3_bucket_items(bucket, prefix, start_after):
    list_items=[]
    
    paginator = s3.get_paginator('list_objects_v2')
    operation_parameters = {'Bucket': bucket,
                            'Prefix': prefix,
                            'StartAfter':start_after}
    page_iterator = paginator.paginate(**operation_parameters)
    for page in page_iterator:
        for item in page['Contents']:
            list_items.append(item['Key'])
    names=list(set([os.path.dirname(x)+'/' for x in list_items]))
    images=[x for x in list_items if x not in names and '.ipynb_checkpoints' not in x ]
    names=[x.replace(prefix,'').strip('/') for x in names if  '.ipynb_checkpoints' not in x]
    return list_items, names, images


docs=[]

train_objects, names, train_images=get_s3_bucket_items(data_bucket, 'idp/textract', 'idp/textract/') 
docs.append(train_images)

if type(docs[0]) is list:
    docs=[item for sublist in docs for item in sublist]
    
names, docs[-10:], docs[:10]

def textract_extract_text(document, bucket=data_bucket):        
    try:
        print(f'Processing document: {document}')
        lines = ""
        row = []
        
        # using amazon-textract-caller
        response = call_textract(input_document=f's3://{bucket}/{document}') 
        # using pretty printer to get all the lines
        lines = get_string(textract_json=response, output_type=[Textract_Pretty_Print.LINES])
        
        label = [name for name in names if(name in document)]  
        row.append(label[0])
        row.append(lines)        
        return row
    except Exception as e:
        print (e)

pool = mp.Pool(mp.cpu_count())
pool_results = [pool.apply_async(textract_extract_text, (document,data_bucket)) for document in docs]
labeled_collection = [res.get() for res in pool_results]
pool.close()

comprehend_df = pd.DataFrame(labeled_collection, columns=['label','document'])
comprehend_df

# Upload Comprehend training data to S3
key='idp/comprehend/comprehend_train_data.csv'

comprehend_df.to_csv("comprehend_train_data.csv", index=False, header=False)
s3.upload_file(Filename='comprehend_train_data.csv', 
               Bucket=data_bucket, 
               Key=key)