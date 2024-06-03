resource "aws_vpc" "vpc" {
  cidr_block                       = local.vpc.cidr
  enable_dns_support               = local.vpc.dnsSupportEnabled
  enable_dns_hostnames             = local.vpc.dnsHostnamesEnabled
  assign_generated_ipv6_cidr_block = local.vpc.ipv6Enabled
  
  tags = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-vpc"
    }
  )
}

resource "aws_subnet" "public" {
  for_each                        = local.public_azs
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, each.value)
  ipv6_cidr_block                 = local.vpc.ipv6Enabled ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, each.value) : null
  availability_zone               = each.key
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = local.vpc.ipv6Enabled

  tags = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-public-${each.key}",
      "Tier" = "public"
    }
  )
}

resource "aws_subnet" "private" {
  for_each                        = local.private_azs
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, sum([local.vpc.countPublicSubnets,each.value]))
  ipv6_cidr_block                 = local.vpc.ipv6Enabled ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, 8, sum([local.vpc.countPublicSubnets,each.value])) : null
  availability_zone               = each.key
  map_public_ip_on_launch         = false
  assign_ipv6_address_on_creation = local.vpc.ipv6Enabled

  tags = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-private-${each.key}",
      "Tier" = "private"
    }
  )
}

# IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-igw"
    }
  )
}

resource "aws_eip" "nat" {
  for_each = local.vpc.useSingleNat ? local.keys_private_azs : toset(keys(local.private_azs))
  
  domain = "vpc"
  tags   = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-nat-${each.key}"
    }
  )
}

resource "aws_nat_gateway" "nat" {
  for_each = local.vpc.useSingleNat ? local.keys_private_azs : toset(keys(local.private_azs))

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  tags = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-nat-gw-${each.key}"
    }
  )
}

# Egress only GW (for ipv6)
resource "aws_egress_only_internet_gateway" "this" {
  count = local.vpc.countPrivateSubnets > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-egress-gw"
    }
  )
}


# Route table for public subnets
resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-public"
    }
  )
}

# Route table for private subnets
resource "aws_route_table" "rt-private" {
  for_each = local.vpc.useSingleNat ? local.keys_private_azs : toset(keys(local.private_azs))
  vpc_id = aws_vpc.vpc.id
  tags   = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-private-${each.key}"
    }
  )
}

resource "aws_route_table_association" "rt-assoc-public" {
  for_each       = local.public_azs
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.rt-public.id
}

resource "aws_route_table_association" "rt-assoc-private" {
  for_each       = toset(keys(local.private_azs))
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = local.vpc.useSingleNat ? aws_route_table.rt-private[keys(local.private_azs)[0]].id : aws_route_table.rt-private[each.key].id
}

resource "aws_route" "public-default-route-ipv4" {
  route_table_id         = aws_route_table.rt-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "public-default-route-ipv6" {
  route_table_id              = aws_route_table.rt-public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw.id
}

resource "aws_route" "private-default-route-ipv4" {
  for_each               = local.vpc.useSingleNat ? local.keys_private_azs : toset(keys(local.private_azs))
  route_table_id         = local.vpc.useSingleNat ? aws_route_table.rt-private[keys(local.private_azs)[0]].id : aws_route_table.rt-private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.vpc.useSingleNat ? aws_nat_gateway.nat[keys(local.private_azs)[0]].id : aws_nat_gateway.nat[each.key].id
}

resource "aws_route" "private-default-route-ipv6" {
  for_each                    = local.vpc.useSingleNat ? local.keys_private_azs : toset(keys(local.private_azs))
  route_table_id              = local.vpc.useSingleNat ? aws_route_table.rt-private[keys(local.private_azs)[0]].id : aws_route_table.rt-private[each.key].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.this[0].id
}

## DHCP Option Set 
resource "aws_vpc_dhcp_options" "dhcp_local" {
  count               = local.vpc.privateDomainName != "" ? 1 : 0
  domain_name         = "${local.vpc.privateDomainName} ${data.aws_region.this.name}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = merge(
    local.commonTags,
    {
      "Name" = "${var.environment}-dhcp-opts"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "dhcp_local_assoc" {
  count           = local.vpc.privateDomainName != "" ? 1 : 0
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_local[count.index].id
}
