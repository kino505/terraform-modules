terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5"
    }
  }
  
  required_version = ">=1.3"
}

provider "aws" {
  region = var.region
  #allowed_account_ids = []
  default_tags {
    tags = {
      Environment = var.environment
      Application = var.application
      Terraform   = "true"
      Source      = "aws/network/vpc"
    }
  }
}
