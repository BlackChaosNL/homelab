terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name         = "jellyfin"
  jellyfin_image         = "docker.io/jellyfin/jellyfin"
  jellyfin_tag           = var.image_tag
  env_file               = "${path.module}/.env"
  jellyfin_internal_port = 8096
  gpus                   = "all"

  jellyfin_volumes = [
    {
      host_path      = "/mnt/storage/media"
      container_path = "/media"
      read_only      = true
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/config"
      container_path = "/config"
      read_only      = false
      }, {
      host_path      = "${var.volume_path}/${local.container_name}/cache"
      container_path = "/cache"
      read_only      = false
    },
  ]

  jellyfin_env_vars = {
    PUID = var.user_id
    PGID = var.group_id
    TZ   = var.timezone
  }
}

module "jellyfin" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.jellyfin_image
  tag            = local.jellyfin_tag
  volumes        = local.jellyfin_volumes
  env_vars       = local.jellyfin_env_vars
  gpus           = local.gpus
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