import streamlit as st
import boto3
import os

# Get bucket name from environment variable
BUCKET_NAME = os.getenv('S3_BUCKET_NAME')

# Create an S3 client
s3 = boto3.client('s3')

# Streamlit app
def main():
    st.title("AWS Intelligent Document Processing")
    st.subheader("Created by HK Transfield")

    # File upload
    uploaded_file = st.file_uploader("Choose a document to upload")

    if uploaded_file is not None:
        if not BUCKET_NAME:
            st.error("S3 bucket name not configured!")
            return

        # Get the file name
        file_name = uploaded_file.name

        try:
            # Upload the file to S3 bucket
            s3.upload_fileobj(uploaded_file, BUCKET_NAME, file_name)
            st.success("File uploaded successfully!")
        except Exception as e:
            st.error(f"Error uploading file: {str(e)}")

if __name__ == '__main__':
    main()
