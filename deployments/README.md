<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.81.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.81.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_captured_documents_bucket"></a> [captured\_documents\_bucket](#module\_captured\_documents\_bucket) | ../modules/document-storage | n/a |
| <a name="module_classified_documents_bucket"></a> [classified\_documents\_bucket](#module\_classified\_documents\_bucket) | ../modules/document-storage | n/a |
| <a name="module_classify_textract_output_lambda_function"></a> [classify\_textract\_output\_lambda\_function](#module\_classify\_textract\_output\_lambda\_function) | ../modules/lambda-function-builder | n/a |
| <a name="module_entity_extraction_and_content_enrichment_lambda_function"></a> [entity\_extraction\_and\_content\_enrichment\_lambda\_function](#module\_entity\_extraction\_and\_content\_enrichment\_lambda\_function) | ../modules/lambda-function-builder | n/a |
| <a name="module_extracted_data_and_enriched_documents_bucket"></a> [extracted\_data\_and\_enriched\_documents\_bucket](#module\_extracted\_data\_and\_enriched\_documents\_bucket) | ../modules/document-storage | n/a |
| <a name="module_human_review_and_validation_lambda_function"></a> [human\_review\_and\_validation\_lambda\_function](#module\_human\_review\_and\_validation\_lambda\_function) | ../modules/lambda-function-builder | n/a |
| <a name="module_results_validation_lambda_function"></a> [results\_validation\_lambda\_function](#module\_results\_validation\_lambda\_function) | ../modules/lambda-function-builder | n/a |
| <a name="module_streamlit_container"></a> [streamlit\_container](#module\_streamlit\_container) | ../modules/app-container | n/a |
| <a name="module_streamlit_load_balancer"></a> [streamlit\_load\_balancer](#module\_streamlit\_load\_balancer) | ../modules/app-load-balancer | n/a |
| <a name="module_streamlit_network"></a> [streamlit\_network](#module\_streamlit\_network) | ../modules/app-network | n/a |
| <a name="module_textract_events"></a> [textract\_events](#module\_textract\_events) | ../modules/textract-event-handler | n/a |
| <a name="module_textract_events_lambda_function"></a> [textract\_events\_lambda\_function](#module\_textract\_events\_lambda\_function) | ../modules/lambda-function-builder | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.job_details](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/resources/dynamodb_table) | resource |
| [aws_lambda_event_source_mapping.textract_output](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/resources/lambda_event_source_mapping) | resource |
| [aws_sns_topic.validation_notifications](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.validation_notifications](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/resources/sns_topic_policy) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy_document.allow_lambda_classify_documents](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.allow_lambda_enrich_content](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.allow_lambda_textract_async_job](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.allow_lambda_validate_document_content](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.human_review_policy](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name of the Sagemaker studio instance | `string` | `"IDPSagemakerDomain"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region name where to deploy the IDP | `string` | `"us-east-1"` | no |
| <a name="input_user_profile_name"></a> [user\_profile\_name](#input\_user\_profile\_name) | The user profile name for the IDP workshop | `string` | `"SageMakerUser"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->