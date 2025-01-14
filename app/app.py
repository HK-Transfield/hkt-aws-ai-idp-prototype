import streamlit as st
import boto3

# Create an S3 client
s3 = boto3.client('s3')

# Streamlit app
def main():
    st.title("AWS Intelligent Document Processing")
    st.subheader("Created by HK Transfield")

    # File upload
    uploaded_file = st.file_uploader("Choose a document to upload")

    if uploaded_file is not None:
        # Get the file name
        file_name = uploaded_file.name

        # Upload the file to S3 bucket
        s3.upload_fileobj(uploaded_file, 'your-s3-bucket-name', file_name)

        st.success("File uploaded successfully!")

if __name__ == '__main__':
    main()