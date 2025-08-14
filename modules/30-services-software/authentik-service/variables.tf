
variable "image_tag" {
  description = "The tag for the authentik container image. Default: 2025.6.4"
  type        = string
  default     = "2025.6.4"
}

variable "redis_image_tag" {
  description = "The tag for the redis container image. Default: alpine"
  type        = string
  default     = "alpine"
}

variable "postgres_image_tag" {
  description = "The tag for the postgres container image. Default: 17-alpine"
  type        = string
  default     = "17-alpine"
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
  default     = "1000"
}

variable "group_id" {
  description = "Group ID for container permissions"
  type        = string
  default     = "1000"
}

variable "timezone" {
  description = "Timezone for the container"
  type        = string
  default     = "Europe/Helsinki"
}