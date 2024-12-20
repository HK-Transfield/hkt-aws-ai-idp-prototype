## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.81.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.6.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.81.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_classify_textract_output_lambda_function"></a> [classify\_textract\_output\_lambda\_function](#module\_classify\_textract\_output\_lambda\_function) | ./modules/lambda-function-builder | n/a |
| <a name="module_enriched_documents"></a> [enriched\_documents](#module\_enriched\_documents) | ./modules/document-storage | n/a |
| <a name="module_input_documents"></a> [input\_documents](#module\_input\_documents) | ./modules/document-storage | n/a |
| <a name="module_textract_events"></a> [textract\_events](#module\_textract\_events) | ./modules/event-driven-updates | n/a |
| <a name="module_textract_updates_lambda_function"></a> [textract\_updates\_lambda\_function](#module\_textract\_updates\_lambda\_function) | ./modules/lambda-function-builder | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_lambda_event_source_mapping.textract_output](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/resources/lambda_event_source_mapping) | resource |
| [random_string.this](https://registry.terraform.io/providers/hashicorp/random/3.6.3/docs/resources/string) | resource |
| [aws_iam_policy_document.allow_lambda_textract_async_job](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_exec_policy](https://registry.terraform.io/providers/hashicorp/aws/5.81.0/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name of the Sagemaker studio instance | `string` | `"IDPSagemakerDomain"` | no |
| <a name="input_user_profile_name"></a> [user\_profile\_name](#input\_user\_profile\_name) | The user profile name for the IDP workshop | `string` | `"SageMakerUser"` | no |

## Outputs

No outputs.
