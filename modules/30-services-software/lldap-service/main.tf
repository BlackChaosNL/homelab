terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name          = "lldap"
  lldap_image             = "ghcr.io/lldap/lldap"
  lldap_tag               = var.image_tag
  env_file                = "${path.module}/.env"
  lldap_internal_port     = 17170

  lldap_volumes = [
    {
      host_path       = "${var.volume_path}/${local.container_name}/data"
      container_path  = "/data"
      read_only       = false
    },
  ]

  lldap_env_vars = {
    LLDAP_JWT_SECRET                 = provider::dotenv::get_by_key("LLDAP_JWT_SECRET", local.env_file)
    LLDAP_BASE_DN                    = provider::dotenv::get_by_key("LLDAP_BASE_DN", local.env_file)
    LLDAP_USER_DN                    = provider::dotenv::get_by_key("LLDAP_USER_DN", local.env_file)
    LLDAP_USER_EMAIL                 = provider::dotenv::get_by_key("LLDAP_USER_EMAIL", local.env_file)
    LLDAP_USER_PASS                  = provider::dotenv::get_by_key("LLDAP_USER_PASS", local.env_file)
    LLDAP_KEY_SEED                   = provider::dotenv::get_by_key("LLDAP_KEY_SEED", local.env_file)
  }
}

module "lldap" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.lldap_image
  tag            = local.lldap_tag
  volumes        = local.lldap_volumes
  env_vars       = local.lldap_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.lldap_internal_port
    endpoint     = "http://${local.container_name}:${local.lldap_internal_port}"
    subdomains   = ["users"]
  }
}