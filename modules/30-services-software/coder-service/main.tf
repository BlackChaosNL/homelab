terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name             = "coder"
  postgres_container_name    = "coder-postgres"
  coder_image                = "ghcr.io/coder/coder"
  postgres_image             = "docker.io/library/postgres"
  coder_tag                  = var.image_tag
  postgres_tag               = var.postgres_image_tag
  env_file                   = "${path.module}/.env"
  coder_internal_port        = 7080

  coder_volumes = [
    {
      host_path      = "/run/user/1000/podman/podman.sock"
      container_path = "/var/run/docker.sock"
      read_only      = false
    }
  ]

  postgres_volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/data"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    }
  ]

  coder_env_vars = {
    CODER_PG_CONNECTION_URL              = "postgresql://${provider::dotenv::get_by_key("POSTGRES_USER", local.env_file)}:${provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)}@coder-postgres/${provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)}?sslmode=disable"
    CODER_HTTP_ADDRESS                   = provider::dotenv::get_by_key("CODER_HTTP_ADDRESS", local.env_file)
    CODER_ACCESS_URL                     = provider::dotenv::get_by_key("CODER_ACCESS_URL", local.env_file)
    CODER_PROXY_TRUSTED_HEADERS          = provider::dotenv::get_by_key("CODER_PROXY_TRUSTED_HEADERS", local.env_file)
    CODER_PROXY_TRUSTED_ORIGINS          = provider::dotenv::get_by_key("CODER_PROXY_TRUSTED_ORIGINS", local.env_file)
    CODER_DISABLE_PASSWORD_AUTH          = provider::dotenv::get_by_key("CODER_DISABLE_PASSWORD_AUTH", local.env_file)
    DOCKER_USER                          = provider::dotenv::get_by_key("DOCKER_USER", local.env_file)
  }

  postgres_env_vars = {
    POSTGRES_USER                        = provider::dotenv::get_by_key("POSTGRES_USER", local.env_file)
    POSTGRES_PASSWORD                    = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
    POSTGRES_DB                          = provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)
  }

}

module "coder_network" {
  source = "../../01-networking/network-service"
  name   = "coder-network"
  subnet = "172.16.0.16/29"
  driver = "bridge"
  options = {
    "isolate": false
  }
}


module "coder-postgres" {
  source         = "../../10-generic/docker-service"
  container_name = local.postgres_container_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
  networks       = [module.coder_network.name]
  restart_policy = "always"
}

module "coder" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.coder_image
  tag            = local.coder_tag
  volumes        = local.coder_volumes
  env_vars       = local.coder_env_vars
  networks       = concat([module.coder_network.name], var.networks)
  restart_policy = "always"
  security_opts = [
    "label:type:container_runtype_t"
  ]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.coder_internal_port
    endpoint     = "http://${local.container_name}:${local.coder_internal_port}"
    subdomains   = ["code"]
  }
}
