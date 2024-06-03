variable region {
  description = "AWS Region"
  type        = string
}

variable environment {
  description = "Environment name. There will for tags, names of almost each resources"
  type        = string
}

variable application {
  description = "Application name"
  type        = string
}

variable vpc {
  default = {}
  description = <<EOT
    "cidr": String
    "countPrivateSubnets": Number
    "countPublicSubnets": Number
    "dnsSupportEnabled": Bool
    "dnsHostnamesEnabled": Bool
    "ipv6Enabled": Bool
    "useSingleNat": Bool
    "privateDomainName": String
  }
EOT
}

data "aws_region" "this" {}

## accessed by ${data.aws_availability_zones.available.names[X]}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  commonTags  = {}
  full_name   = "${var.application}-${var.environment}"
  private_azs = {for i in range(local.vpc.countPrivateSubnets): data.aws_availability_zones.available.names[i] => i}
  public_azs  = {for i in range(local.vpc.countPublicSubnets): data.aws_availability_zones.available.names[i] => i}
  
  keys_private_azs = toset([try(keys(local.private_azs)[0],[])])

  default_vpc = {
    "cidr": "10.0.0.0/16",
    "countPrivateSubnets": 0,
    "countPublicSubnets": 3,
    "dnsSupportEnabled": true,
    "dnsHostnamesEnabled": true,
    "ipv6Enabled": false,
    "useSingleNat": true,
    "privateDomainName": ""
  }
  vpc = merge(local.default_vpc,var.vpc)
}
