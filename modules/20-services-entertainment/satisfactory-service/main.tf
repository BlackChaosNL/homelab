terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name             = "satisfactory"
  satisfactory_image         = "ghcr.io/wolveix/satisfactory-server"
  satisfactory_tag           = var.image_tag
  env_file                   = "${path.module}/.env"
  satisfactory_internal_port = 7777
}



module "satisfactory" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.satisfactory_image
  tag            = local.satisfactory_tag
  networks       = var.networks
  restart_policy = "always"
  memory_limit   = 16000 // 16Gb
  ports = [
    {
      internal = 7777
      external = 7777
      protocol = "tcp"
    },
    {
      internal = 7777
      external = 7777
      protocol = "udp"
    },
    {
      internal = 8888
      external = 8888
      protocol = "tcp"
    }
  ]
  volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/config"
      container_path = "/config"
      read_only      = false
    },
  ]
  env_vars = {
    MAXPLAYERS   = provider::dotenv::get_by_key("MAXPLAYERS", local.env_file)
    PUID         = var.user_id
    PGID         = var.group_id
  }
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.satisfactory_internal_port
    endpoint     = "http://${local.container_name}:${local.satisfactory_internal_port}"
  }
}
