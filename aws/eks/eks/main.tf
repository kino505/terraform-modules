module "vpc" {
    source      = "git@github.com:kino505/terraform-modules.git//aws/network/vpc?ref=eks"
    application = var.application
    environment = var.environment
    region      = var.region
    vpc         = var.infrastructure.vpc
}

module "cluster" {
    source      = "git@github.com:kino505/terraform-modules.git//aws/eks/cluster?ref=eks"
    application = var.application
    eks         = module.deepmerge.merged
    environment = var.environment
    region      = var.region
}

module "deepmerge" {
  source  = "git@github.com:kino505/terraform-modules.git//tools/deepmerge?ref=eks"
  maps = [
    var.eks,
    {
      "eks": {
        "vpc_config": {
          "subnet_ids": module.vpc.private_subnet_ids
        }
      }
    }
  ]
}