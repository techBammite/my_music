terraform {
  required_version = ">= 1.5.0"

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

  # Pour activer le backend remote S3 après la création initiale du bucket S3:
  # backend "s3" {
  #   bucket         = "mymusic-tf-state-bucket"
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
