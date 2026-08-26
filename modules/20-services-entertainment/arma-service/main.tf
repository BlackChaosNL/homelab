terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name = "arma3"
  image          = "ghcr.io/gameservermanagers/gameserver"
  tag            = var.image_tag
  env_file       = "${path.module}/.env"
  internal_port  = 2344
}

module "arma3" {
  source            = "../../10-generic/docker-service"
  container_name    = local.container_name
  image             = local.image
  tag               = local.tag
  networks          = var.networks
  memory_limit      = 8192
  memory_swap_limit = 4096
  restart_policy    = "always"
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
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
  }
}
