variable "image_tag" {
  description = "The tag for the Pelican container image. Default: latest"
  type        = string
  default     = "latest"
}

variable "wings_image_tag" {
  description = "The tag for the Pelican Wings container image. Default: latest"
  type        = string
  default     = "latest"
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
