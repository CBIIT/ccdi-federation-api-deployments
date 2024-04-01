terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.66.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ApplicationName = "Federation API"
      project         = "federation"
    }
  }
}