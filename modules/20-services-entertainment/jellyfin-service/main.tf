terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

variable "image_tag" {
  description = "The tag for the JellyFin container image. Default: Latest"
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

locals {
  container_name          = "jellyfin"
  jellyfin_image           = "docker.io/jellyfin/jellyfin"
  jellyfin_tag             = var.image_tag
  env_file                = "${path.module}/.env"
  jellyfin_internal_port  = 8096

  jellyfin_volumes = [
    {
      host_path      = "/mnt/storage/media"
      container_path = "/media"
      read_only      = true
    },
    {
      host_path      = "${volume_path}/${container_name}/config"
      container_path = "/config"
    },{
      host_path      = "${volume_path}/${container_name}/cache"
      container_path = "/cache"
    },
  ]

  jellyfin_env_vars = {
    PUID        = var.user_id
    PGID        = var.group_id
    TZ          = var.timezone
  }
}

module "jellyfin" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.jellyfin_image
  tag            = local.jellyfin_tag
  volumes        = local.jellyfin_volumes
  env_vars       = local.jellyfin_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.jellyfin_internal_port
    endpoint     = "http://${local.container_name}:${local.jellyfin_internal_port}"
    subdomains   = ["tv"]
  }
}