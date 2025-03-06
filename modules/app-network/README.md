# VPC Network Infrastructure 🌐

* Assigned a CIDR block of 10.17.0.0/16.

## Subnets

### Availability Zone A


| NAME     | CIDR          | AZ  | CustomIPv6Value |
| ---------- | --------------- | ----- | ----------------- |
| sn-db-A  | 10.17.16.0/20 | AZA | IPv6 01         |
| sn-app-A | 10.17.32.0/20 | AZA | IPv6 02         |
| sn-web-A | 10.17.48.0/20 | AZA | IPv6 03         |

### Availability Zone B


| NAME     | CIDR           | AZ  | CustomIPv6Value |
| ---------- | ---------------- | ----- | ----------------- |
| sn-db-B  | 10.17.80.0/20  | AZB | IPv6 05         |
| sn-app-B | 10.17.96.0/20  | AZB | IPv6 06         |
| sn-web-B | 10.17.112.0/20 | AZB | IPv6 07         |

## Internet Gateway

* An IGW is assigned to the VPC.

## Route Tables

* A route table is attached to the VPC, and associated with the public web
  subnets in each AZ.
* The following default routes were added:
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_security_group_egress_rule.allow_outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.allow_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | CIDR block for VPC | `string` | n/a | yes |
| <a name="input_private_sn"></a> [private\_sn](#input\_private\_sn) | Private application subnet CIDR values | <pre>map(object({<br/>    cidr_block             = string<br/>    ipv6_cidr_block_netnum = number<br/>    availability_zone      = string<br/>  }))</pre> | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | For naming resources according to the project | `string` | n/a | yes |
| <a name="input_project_tags"></a> [project\_tags](#input\_project\_tags) | n/a | `map(string)` | n/a | yes |
| <a name="input_public_sn"></a> [public\_sn](#input\_public\_sn) | Public web subnet CIDR values | <pre>map(object({<br/>    cidr_block             = string<br/>    ipv6_cidr_block_netnum = number<br/>    availability_zone      = string<br/>  }))</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `"ap-southeast-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_a_subnet_id"></a> [private\_a\_subnet\_id](#output\_private\_a\_subnet\_id) | n/a |
| <a name="output_private_b_subnet_id"></a> [private\_b\_subnet\_id](#output\_private\_b\_subnet\_id) | n/a |
| <a name="output_public_a_subnet_id"></a> [public\_a\_subnet\_id](#output\_public\_a\_subnet\_id) | n/a |
| <a name="output_public_b_subnet_id"></a> [public\_b\_subnet\_id](#output\_public\_b\_subnet\_id) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->