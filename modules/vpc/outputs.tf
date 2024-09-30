
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnets" {
  value = aws_subnet.private_subnet[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block 
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "default_security_group_id" {
  value = aws_security_group.default_ssh.id
}