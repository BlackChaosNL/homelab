terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name = "vaultwarden"
  image          = "docker.io/vaultwarden/server"
  tag            = var.image_tag
  env_file       = "${path.module}/.env"
  internal_port  = 80

  env_vars = {
    DOMAIN = "https://vaultwarden.blackchaosnl.myaddr.dev"
    ADMIN_TOKEN = provider::dotenv::get_by_key("ADMIN_TOKEN", local.env_file)
  }
}

module "vaultwarden" {
    source         = "../../10-generic/docker-service"
    container_name = local.container_name
    image          = local.image
    tag            = local.tag
    volumes        = [ 
        {
            host_path = "${var.volume_path}/${local.container_name}/data"
            container_path = "/data"
            read_only = false
        }
    ]
    env_vars       = local.env_vars
    networks       = concat(var.networks)
    restart_policy = "always"
}


output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["vaultwarden"]
  }
}