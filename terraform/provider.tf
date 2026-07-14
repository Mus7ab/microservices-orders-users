terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
backend "s3" {
    bucket       = "microservices-orders-users-tfstate-342677169816"
    key          = "microservices-orders-users/terraform.tfstate"
    region       = "ap-south-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}
