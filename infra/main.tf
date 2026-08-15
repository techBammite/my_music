terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Le backend S3 nécessite que le bucket existe au préalable.
  # backend "s3" {
  #   bucket         = "mymusic-deploy-v1"
  #   key            = "terraform.tfstate"
  #   region         = "eu-west-3"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "MyMusic"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
