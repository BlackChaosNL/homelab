terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name         = "tandoor"
  postgres_name          = "tandoor-postgres"
  tandoor_image          = "docker.io/vabene1111/recipes"
  postgres_image         = "docker.io/library/postgres"
  tandoor_tag            = var.image_tag
  postgres_tag           = var.postgres_image_tag
  env_file               = "${path.module}/.env"
  tandoor_internal_port  = 8080

  tandoor_volumes = [
    {
      host_path      = "/mnt/storage/media"
      container_path = "/media"
      read_only      = true
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/config"
      container_path = "/config"
      read_only      = false
    },{
      host_path      = "${var.volume_path}/${local.container_name}/cache"
      container_path = "/cache"
      read_only      = false
    },
  ]

    postgres_volumes = [
    {
      host_path       = "${var.volume_path}/${local.container_name}/postgres/data"
      container_path  = "/var/lib/postgresql/data"
      read_only       = false
    },
  ]

  tandoor_env_vars = {
    SECRET_KEY                       = provider::dotenv::get_by_key("SECRET_KEY", local.env_file)
    DEBUG                            = provider::dotenv::get_by_key("DEBUG", local.env_file)
    ALLOWED_HOSTS                    = provider::dotenv::get_by_key("ALLOWED_HOSTS", local.env_file)
    DB_ENGINE                        = provider::dotenv::get_by_key("DB_ENGINE", local.env_file)
    POSTGRES_HOST                    = provider::dotenv::get_by_key("POSTGRES_HOST", local.env_file)
    POSTGRES_DB                      = provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)
    POSTGRES_PORT                    = provider::dotenv::get_by_key("POSTGRES_PORT", local.env_file)
    POSTGRES_USER                    = provider::dotenv::get_by_key("POSTGRES_USER", local.env_file)
    POSTGRES_PASSWORD                = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
  }

  postgres_env_vars = {
    POSTGRES_PASSWORD                = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
    POSTGRES_USER                    = provider::dotenv::get_by_key("POSTGRES_USER", local.env_file)
    POSTGRES_DB                      = provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)
  }
}

module "tandoor_network" {
  source = "../../01-networking/network-service"
  name   = "tandoor-network"
  subnet = "172.16.0.24/29"
  driver = "bridge"
  options = {
    "isolate": false
  }
}

module "tandoor-postgres" {
  source         = "../../10-generic/docker-service"
  container_name = local.postgres_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
  networks       = [module.tandoor_network.name]
}

module "tandoor" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.tandoor_image
  tag            = local.tandoor_tag
  volumes        = local.tandoor_volumes
  env_vars       = local.tandoor_env_vars
  networks       = concat([module.tandoor_network.name], var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.tandoor_internal_port
    endpoint     = "http://${local.container_name}:${local.tandoor_internal_port}"
    subdomains   = ["tandoor"]
    is_guarded   = true
  }
}
