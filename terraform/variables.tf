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

variable "federation_apis" {
  type        = string
  description = "apis accessed by the ccdi federation api service"
}

variable "new_relic_account_id" {
  type      = string
  sensitive = true
}

variable "new_relic_metrics_api_key" {
  type      = string
  sensitive = true
}

variable "new_relic_sidecar_api_key" {
  type      = string
  sensitive = true
}

variable "sumo_logic_api_key" {
  type      = string
  sensitive = true
}

variable "central_ecr_account_id" {
  type      = string
  sensitive = true
}

variable "newrelic_s3_bucket" {
  type        = string
  description = "the bucket to use for failed metrics"
}
