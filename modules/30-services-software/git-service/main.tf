terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name            = "gitea"
  image                     = "docker.gitea.com/gitea"
  tag                       = var.image_tag
  internal_port             = 3000
}

module "gitea" {
    source         = "../../10-generic/docker-service"
    container_name = local.container_name
    image          = local.image
    tag            = local.tag
    volumes        = [
        {
            host_path      = "${var.volume_path}/data"
            container_path = "/data"
            read_only      = false
        },
    ]
    ports = [
        {
            internal = 22
            external = 2222
            protocol = "tcp"
        },
        {
            internal = 22
            external = 2222
            protocol = "udp"
        }
    ]
    networks       = concat(var.networks)
    restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["git"]
  }
}