variable "image_tag" {
  description = "The tag for the coder container image. Default: Latest"
  type        = string
  default     = "latest"
}

variable "postgres_image_tag" {
  description = "The tag for the postgres container image. Default: Latest"
  type        = string
  default     = "17-alpine"
}

variable "valkey_image_tag" {
  description = "Valkey K/V store container image. Default: 8.1"
  type        = string
  default     = "8.1"
}

variable "volume_path" {
  description = "Base directory for volumes"
  type        = string
}

variable "networks" {
  description = "List of networks to which the container should be attached"
  type        = list(string)
  default     = []
}

variable "user_id" {
  description = "User ID for container permissions"
  type        = string
  default     = "1001"
}

variable "group_id" {
  description = "Group ID for container permissions"
  type        = string
  default     = "1001"
}

variable "timezone" {
  description = "Timezone for the container"
  type        = string
  default     = "Europe/Helsinki"
}