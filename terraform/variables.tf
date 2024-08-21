variable "federation_apis" {
  type        = string
  description = "apis accessed by the ccdi federation api service"
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

variable "new_relic_account_id" {
  description = "the New Relic tenant account ID"
  type        = string
  sensitive   = true
}

variable "new_relic_api_key" {
  description = "the New Relic API key"
  type        = string
  sensitive   = true
}

variable "program" {
  description = "the program name"
  type        = string
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
  default     = {}
}

variable "sumo_logic_api_key" {
  description = "the Sumo Logic API key defined in the collector endpoint"
  type        = string
  sensitive   = true
}

variable "central_ecr_account_id" {
  description = "the central ECR AWS Account ID"
  type        = string
  sensitive   = true
}
