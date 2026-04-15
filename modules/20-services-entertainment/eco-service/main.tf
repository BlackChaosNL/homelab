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
  eco_token         = provider::dotenv::get_by_key("TOKEN", local.env_file)
}

module "eco" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.eco_image
  tag            = local.eco_tag
  networks       = var.networks
  restart_policy = "always"
  command        = [ "./EcoServer", "--nogui", "--userToken=${local.eco_token}" ]
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
    }
  ]
}


output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.eco_internal_port
    endpoint     = "http://${local.container_name}:${local.eco_internal_port}"
  }
}
