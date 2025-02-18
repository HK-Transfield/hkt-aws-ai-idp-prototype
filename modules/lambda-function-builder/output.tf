/*
Name:     Lambda Function Builder Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2024
*/

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}