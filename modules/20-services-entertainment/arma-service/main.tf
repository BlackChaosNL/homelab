terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name      = "arma3"
  arma3_image         = "ghcr.io/gameservermanagers/gameserver"
  arma3_tag           = var.image_tag
  env_file            = "${path.module}/.env"
  arma3_internal_port = 2344
}

module "arma3" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.arma3_image
  tag            = local.arma3_tag
  networks       = var.networks
  restart_policy = "always"
  ports = [
    {
      internal = 2344
      external = 2344
      protocol = "udp"
    },
    {
      internal = 2344
      external = 2344
      protocol = "tcp"
    },
    {
      internal = 2345
      external = 2345
      protocol = "tcp"
    },
    {
      internal = 2302
      external = 2302
      protocol = "udp"
    },
    {
      internal = 2303
      external = 2303
      protocol = "udp"
    },
    {
      internal = 2304
      external = 2304
      protocol = "udp"
    },
    {
      internal = 2305
      external = 2305
      protocol = "udp"
    },
    {
      internal = 2306
      external = 2306
      protocol = "udp"
    }
  ]
  volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/data"
      container_path = "/data"
      read_only      = false
    }
  ]
}


output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.arma3_internal_port
    endpoint     = "http://${local.container_name}:${local.arma3_internal_port}"
  }
}
