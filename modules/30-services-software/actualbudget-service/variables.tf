variable "image_tag" {
  description = "Tag of the ActualBudget image to use. Default: latest-alpine"
  type        = string
  default     = "latest-alpine"
}

variable "volume_path" {
  description = "Host path for ActualBudget data volume"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
}