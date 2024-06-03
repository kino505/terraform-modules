output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr_ipv4" {
  value = aws_vpc.vpc.cidr_block
}

output "vpc_cidr_ipv6" {
  value = local.vpc.ipv6Enabled ? aws_vpc.vpc.ipv6_cidr_block : ""
}

output "vpc_name" {
  value = "${var.environment}-vpc"
}

output "public_subnet_ids" {
  value = [
    for az in keys(local.public_azs): aws_subnet.public[az].id
  ]
}

output "private_subnet_ids" {
  value = [
    for az in keys(local.private_azs): aws_subnet.private[az].id
  ]
}
