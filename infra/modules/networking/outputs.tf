output "vpc_id" {
  description = "ID of the VPC"
  value = aws_vpc.this.id
}
output "subnets_id" {
  description = "ID of the subnets"
  value = { for k, v in aws_subnet.managed : k => v.id }
}
