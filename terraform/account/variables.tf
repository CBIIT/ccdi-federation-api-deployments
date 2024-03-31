variable "app" {
  type        = string
  description = "The name of the application used to source logs"
  default     = "ins"
}

variable "program" {
  type        = string
  description = "The program that the application belongs to"
  default     = "ccdi"
}

variable "iam_prefix" {
  type        = string
  description = "The IAM prefix for Role and Policy resource names"
  default     = "power-user"
}

# variables for metric_steam
variable "new_relic_account_id" {
  type        = string
  description = "The external id for the delivery stream trust policy condition"
}

variable "http_endpoint_access_key" {
  type        = string
  description = "The access key required for Kinesis Firehose to authenticate with the HTTP endpoint selected as the destination"
}