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
    eks         = merge(
        var.eks,
        {"eks.vpc_config.subnet_ids": module.vpc.private_subnet_ids}
    )
    environment = var.environment
    region      = var.region
}