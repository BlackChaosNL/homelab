variable "container_name" {
  description = "The name of the Caddy container"
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "The tag of the Caddy Docker image to use"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "domains" {
  description = "Which domain names to use for services"
  type        = list(string)
}

variable "tls_email" {
  description = "Email address to use for TLS certificate generation with Let's Encrypt"
  type        = string
}

variable "service_definitions" {
  description = "List of service definitions to evaluate for exposure through Caddy"
  type = list(object({
    name          = string
    endpoint      = string
    subdomains    = optional(list(string), [])
    publish_via   = optional(string)
    caddy_config  = optional(string, "")
    caddy_options = optional(map(string), {})
    is_guarded    = optional(bool, false)
  }))
}

variable "networks" {
  description = "List of Docker networks to connect the Caddy container to"
  type        = list(string)
  default     = []
}
