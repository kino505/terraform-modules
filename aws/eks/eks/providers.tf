terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5"
    }
    tls = {
      source  = "hashicorp/tls"
      #version = "~> 3.0"
    }
  }
  
  required_version = ">=1.3"
  backend "s3" {}
}

provider "aws" {
  region = var.region
  #allowed_account_ids = []
  default_tags {
    tags = {
      Environment = var.environment
      Application = var.application
      Terraform   = "true"
      Source      = "aws/eks/eks"
    }
  }
}
