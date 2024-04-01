variable "program" {
  type        = string
  description = "the program name"
  default     = "ccdi"
}

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

# Secrets
variable "secret_values" {
  type = map(object({
    secretKey   = string
    secretValue = map(string)
    description = string
  }))
}

variable "central_ecr_account_id" {
  type        = string
  description = "central ecr account number"
}

variable "service" {
  type        = string
  description = "Name of the service where the monitoring is configured. example ecs, database etc"
}
