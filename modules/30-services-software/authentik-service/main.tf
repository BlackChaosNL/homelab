terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name          = "authentik"
  redis_container_name    = "authentik-redis"
  postgres_container_name = "authentik-postgres"
  authentik_image         = "ghcr.io/goauthentik/server"
  redis_image             = "docker.io/library/redis"
  postgres_image          = "docker.io/library/postgres"
  authentik_tag           = var.image_tag
  redis_tag               = var.redis_image_tag
  postgres_tag            = var.postgres_image_tag
  env_file                = "${path.module}/.env"
  authentik_internal_port = 9000

  authentik_content = <<-EOT
  EOT

  authentik_volumes = [
    {
      host_path       = "${var.volume_path}/${local.container_name}/media"
      container_path  = "/media"
      read_only       = false
    },
    {
      host_path       = "${var.volume_path}/${local.container_name}/custom-templates"
      container_path  = "/templates"
      read_only       = false
    },
    {
      host_path       = "${var.volume_path}/${local.container_name}/user_settings.py"
      container_path  = "/data/user_settings.py"
      read_only       = false
    }
  ]

  redis_volumes = [
    {
      host_path       = "${var.volume_path}/${local.container_name}/redis/data"
      container_path  = "/data"
      read_only       = false
    },
  ]

  postgres_volumes = [
    {
      host_path       = "${var.volume_path}/${local.container_name}/postgres/data"
      container_path  = "/var/lib/postgresql/data"
      read_only       = false
    },
  ]

  authentik_env_vars = {
    AUTHENTIK_SECRET_KEY             = provider::dotenv::get_by_key("AUTHENTIK_SECRET_KEY", local.env_file)
    AUTHENTIK_REDIS__HOST            = provider::dotenv::get_by_key("AUTHENTIK_REDIS__HOST", local.env_file)
    AUTHENTIK_POSTGRESQL__HOST       = provider::dotenv::get_by_key("AUTHENTIK_POSTGRESQL__HOST", local.env_file)
    AUTHENTIK_POSTGRESQL__USER       = provider::dotenv::get_by_key("AUTHENTIK_POSTGRESQL__USER", local.env_file)
    AUTHENTIK_POSTGRESQL__NAME       = provider::dotenv::get_by_key("AUTHENTIK_POSTGRESQL__NAME", local.env_file)
    AUTHENTIK_POSTGRESQL__PASSWORD   = provider::dotenv::get_by_key("AUTHENTIK_POSTGRESQL__PASSWORD", local.env_file)
  }

  postgres_env_vars = {
    POSTGRES_PASSWORD                = provider::dotenv::get_by_key("AUTHENTIK_POSTGRESQL__PASSWORD", local.env_file)
    POSTGRES_USER                    = provider::dotenv::get_by_key("AUTHENTIK_POSTGRESQL__USER", local.env_file)
    POSTGRES_DB                      = provider::dotenv::get_by_key("AUTHENTIK_POSTGRESQL__DB", local.env_file)
  }
}

  resource "local_file" "authentik_config_file" {
    content  = local.authentik_content
    filename = "${var.volume_path}/${local.container_name}/user_settings.py"
  }

module "authentik_network" {
  source = "../../01-networking/network-service"
  name   = "authentik-network"
  subnet = "172.16.0.0/29"
  driver = "bridge"
  options = {
    "isolate": false
  }
}

module "authentik-postgres" {
    source         = "../../10-generic/docker-service"
    container_name = local.postgres_container_name
    image          = local.postgres_image
    tag            = local.postgres_tag
    volumes        = local.postgres_volumes
    env_vars       = local.postgres_env_vars
    networks       = [module.authentik_network.name]
}

module "authentik-redis" {
    source         = "../../10-generic/docker-service"
    container_name = local.redis_container_name
    image          = local.redis_image
    tag            = local.redis_tag
    volumes        = local.redis_volumes
    networks       = [module.authentik_network.name]
}

module "authentik-server" {
    source         = "../../10-generic/docker-service"
    container_name = local.container_name
    image          = local.authentik_image
    tag            = local.authentik_tag
    volumes        = local.authentik_volumes
    env_vars       = local.authentik_env_vars
    networks       = concat([module.authentik_network.name], var.networks)
    command        = ["server"]
}

module "authentik-worker" {
    source         = "../../10-generic/docker-service"
    container_name = "${local.container_name}-worker"
    image          = local.authentik_image
    tag            = local.authentik_tag
    volumes        = local.authentik_volumes
    env_vars       = local.authentik_env_vars
    networks       = [module.authentik_network.name]
    command        = ["worker"]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.authentik_internal_port
    endpoint     = "http://${local.container_name}:${local.authentik_internal_port}"
    subdomains   = ["authz"]
  }
}
