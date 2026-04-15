terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name    = "eco"
  eco_image         = "docker.io/strangeloopgames/eco-game-server"
  eco_tag           = var.image_tag
  env_file          = "${path.module}/.env"
  eco_internal_port = 3000
}

module "eco" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.eco_image
  tag            = local.eco_internal_port
  networks       = var.networks
  restart_policy = "always"
  ports = [
    {
      internal = 3000
      external = 3000
      protocol = "udp"
    },
    {
      internal = 3001
      external = 3001
      protocol = "tcp"
    }
  ]
  volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/config"
      container_path = "/app/Configs/"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/data"
      container_path = "/app/Storage/"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/mods"
      container_path = "/app/Mods/"
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
    primary_port = local.eco_internal_port
    endpoint     = "http://${local.container_name}:${local.eco_internal_port}"
  }
}
