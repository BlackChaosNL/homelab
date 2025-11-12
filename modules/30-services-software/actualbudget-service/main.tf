terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name = "actualbudget"
  image          = "ghcr.io/actualbudget/actual"
  image_tag      = var.image_tag
  env_file       = "${path.module}/.env"
  internal_port  = 5006

  default_volumes = [
    {
      host_path      = "${var.volume_path}/data"
      container_path = "/data"
      read_only      = false
    }
  ]

  actualbudget_env_vars = {
    ACTUAL_OPENID_DISCOVERY_URL   = provider::dotenv::get_by_key("ACTUAL_OPENID_DISCOVERY_URL", local.env_file)
    ACTUAL_OPENID_CLIENT_ID       = provider::dotenv::get_by_key("ACTUAL_OPENID_CLIENT_ID", local.env_file)
    ACTUAL_OPENID_CLIENT_SECRET   = provider::dotenv::get_by_key("ACTUAL_OPENID_CLIENT_SECRET", local.env_file)
    ACTUAL_OPENID_SERVER_HOSTNAME = provider::dotenv::get_by_key("ACTUAL_OPENID_SERVER_HOSTNAME", local.env_file)
    ACTUAL_ALLOWED_LOGIN_METHODS  = provider::dotenv::get_by_key("ACTUAL_ALLOWED_LOGIN_METHODS", local.env_file)
  }
}

module "actualbudget" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.image_tag
  volumes        = local.default_volumes
  env_vars       = local.actualbudget_env_vars
  networks       = var.networks
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["budget"]
  }
}