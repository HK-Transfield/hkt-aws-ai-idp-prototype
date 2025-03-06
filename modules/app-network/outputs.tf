output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_a_subnet_id" {
  value = aws_subnet.public["A"].id
}

output "public_b_subnet_id" {
  value = aws_subnet.public["B"].id
}

output "private_a_subnet_id" {
  value = aws_subnet.private["A"].id
}

output "private_b_subnet_id" {
  value = aws_subnet.private["B"].id
}