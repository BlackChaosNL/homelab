variable "image_tag" {
  description = "The tag of the Caddy Docker image to use"
  type        = string
  default     = "latest"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}