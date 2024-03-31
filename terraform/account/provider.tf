terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.26.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Customer       = "NCI OD CBIIT ODS"
      DevLead        = "Wei Yu"
      DevOps         = "Venkata Sai Kiran Kotepalli"
      FISMA          = "Low"
      ManagedBy      = "terraform"
      OpsModel       = "CBIIT Managed Hybrid"
      Program        = "CCDI"
      PII            = "No"
      Project        = "INS"
      ProjectManager = "Anita Johnson"
    }
  }
}