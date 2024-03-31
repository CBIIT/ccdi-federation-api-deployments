################################################################################################################
## General Variables ###########################################################################################
################################################################################################################

variable "app" {
  type        = string
  description = "the name of the application (acronym)"
  default     = "ins"
  sensitive   = false
}

variable "manager_account_id" {
  type        = string
  description = "the account id of the manager account"
  sensitive   = true
}

variable "program" {
  type        = string
  description = "the name of the program the app is associated with"
  default     = "ccdi"
  sensitive   = false
}

variable "region" {
  description = "aws region to use for this resource"
  type        = string
  default     = "us-east-1"
}

##################################
##  Jenkins Host Variables  ######
##################################

variable "jenkins_host_id" {
  type        = string
  description = "The ID of the EC2 instance hosting Jenkins in the account"
}

variable "jenkins_cidr" {
  type        = list(string)
  description = "The IP range for the subnet that the Jenkins instance is hosted within"
}

##################################
##  Secrets Manager Variables  ###
##################################

variable "secrets" {
  type        = map(string)
  description = "all the secrets that needs to be saved in the secrets manager is passed here"
  default     = {}
}

##################################
##  CloudWatch Variables  ########
##################################

variable "allow_cloudwatch_stream" {
  type        = bool
  description = "allow cloudwatch stream for the containers"
  default     = true
}

################################################################################################################
## S3 Variables ################################################################################################
################################################################################################################

variable "etl_bucket_suffix" {
  type        = string
  description = "the suffix of the bucket name following program-env-app"
  default     = "etl-bucket"
  sensitive   = false
}

variable "aws_nonprod_account_id" {
  type = map(string)
  description = "aws account to allow for cross account access"
  default = {
    us-east-1 = "082604052123"
  }
}

#Opensearch snapshot bucket
variable "s3_opensearch_snapshot_bucket" {
  type = string
  description = "name of the S3 Opensearch snapshot bucket created in prod account"
  sensitive   = false
  default = "ccdi-stage-ins-opensearch-snapshot-bucket"
}