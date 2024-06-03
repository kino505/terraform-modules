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

variable eks {
  default = {}
  description = <<EOT
    
  }
EOT
}

locals {
  commonTags   = {}
  full_name    = "${var.application}-${var.environment}"
  cluster_name = try(local.eks.full_name,local.full_name)

  #https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
  default_eks = {
    "enabled_cluster_log_types": ["api", "audit","authenticator","controllerManager","scheduler"],
    "retention_in_days": 7,
    "vpc_config": {
      "endpoint_private_access": false,
      "endpoint_public_access": true,
      "public_access_cidr": "0.0.0.0/0",
      "security_group_ids": [],
      "subnet_ids": []
    },
    "access_config": {}
    "encryption_config": {},
    "kubernetes_network_config": {},
    "encryption_config": {},
    "version": null
  }
  eks = merge(local.default_eks,var.eks)
}
