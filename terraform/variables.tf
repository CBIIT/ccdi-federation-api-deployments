variable "project" {
  description = "name of the project"
  type        = string
  default     = "federation"
}

variable "tags" {
  description = "tags to associate with this instance"
  type        = map(string)
}

variable "microservices" {
  type = map(object({
    name                      = string
    port                      = number
    health_check_path         = string
    priority_rule_number      = number
    image_url                 = string
    cpu                       = number
    memory                    = number
    path                      = list(string)
    number_container_replicas = number
  }))
}

variable "domain_name" {
  description = "domain name for the application"
  type        = string
}

variable "iam_prefix" {
  type        = string
  default     = "power-user"
  description = "nci iam power user prefix"
}

# ALB
variable "certificate_domain_name" {
  description = "domain name for the ssl cert"
  type        = string
}


variable "s3_force_destroy" {
  description = "force destroy bucket"
  default     = true
  type        = bool
}

# ECS


variable "allow_cloudwatch_stream" {
  type        = bool
  default     = true
  description = "allow cloudwatch stream for the containers"
}

variable "application_subdomain" {
  description = "subdomain of the app"
  type        = string
}

# Instance Profile
variable "create_instance_profile" {
  type        = bool
  default     = false
  description = "set to create instance profile"
}

# Monitoring
variable "sumologic_access_id" {
  type        = string
  description = "Sumo Logic Access ID"
}
variable "sumologic_access_key" {
  type        = string
  description = "Sumo Logic Access Key"
  sensitive   = true
}

# Newrelic Metrics
variable "account_level" {
  type        = string
  description = "whether the account is prod or non-prod"
}

variable "create_newrelic_pipeline" {
  type        = bool
  description = "whether to create the newrelic pipeline"
  default     = false
}

variable "newrelic_account_id" {
  type        = string
  description = "Newrelic Account ID"
  sensitive   = true
}

variable "newrelic_api_key" {
  type        = string
  description = "Newrelic API Key"
  sensitive   = true
}

variable "newrelic_s3_bucket" {
  type        = string
  description = "the bucket to use for failed metrics"
}

variable "program" {
  type        = string
  description = "the program name"
  default     = "ccdi"
}

# Secrets
variable "secret_values" {
  type = map(object({
    secretKey   = string
    secretValue = map(string)
    description = string
  }))
}

# Security Group
variable "allowed_ip_blocks" {
  description = "allowed ip block for the opensearch/mysql"
  type        = list(string)
  default     = []
}

variable "bastion_host_security_group_id" {
  description = "security group id of the bastion host"
  type        = string
  default     = "sg-0c94322085acbfd97"
}

variable "katalon_security_group_id" {
  description = "security group id of the bastion host"
  type        = string
  default     = "sg-0f07eae0a9b3a0bb8"
}

variable "central_ecr_account_id" {
  type        = string
  description = "central ecr account number"
}

variable "service" {
  type        = string
  description = "Name of the service where the monitoring is configured. example ecs, database etc"
}
