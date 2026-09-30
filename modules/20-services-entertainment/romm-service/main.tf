terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name          = "romm"
  postgres_container_name = "romm-postgres"
  valkey_container_name   = "romm-valkey"
  container_image         = "ghcr.io/rommapp/romm"
  postgres_image          = "docker.io/library/postgres"
  valkey_image            = "docker.io/valkey/valkey"
  container_tag           = var.image_tag
  postgres_tag            = var.postgres_image_tag
  valkey_tag              = var.valkey_image_tag
  env_file                = "${path.module}/.env"
  internal_port           = 8080

  romm_volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/resources"
      container_path = "/romm/resources"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/library"
      container_path = "/romm/library"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/assets"
      container_path = "/romm/assets"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/config"
      container_path = "/romm/config"
      read_only      = false
    },
  ]

  redis_volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/redis/data"
      container_path = "/data"
      read_only      = false
    },
  ]

  postgres_volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/postgres/data"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    },
  ]

  romm_env_vars = {
    ROMM_DB_DRIVER              = "postgresql"
    DB_HOST                     = local.postgres_container_name
    DB_NAME                     = provider::dotenv::get_by_key("ROMM_POSTGRESQL_DB", local.env_file)
    DB_USER                     = provider::dotenv::get_by_key("ROMM_POSTGRESQL_USER", local.env_file)
    DB_PASSWD                   = provider::dotenv::get_by_key("ROMM_POSTGRESQL_PASSWORD", local.env_file)
    REDIS_HOST                  = local.valkey_container_name
    REDIS_PORT                  = 6379
    ROMM_AUTH_SECRET_KEY        = provider::dotenv::get_by_key("ROMM_SECRET_KEY", local.env_file)
    PLAYMATCH_API_ENABLED       = true
    IGDB_CLIENT_ID              = provider::dotenv::get_by_key("ROMM_IGDB_CLIENT_ID", local.env_file)
    IGDB_CLIENT_SECRET          = provider::dotenv::get_by_key("ROMM_IGDB_CLIENT_SECRET", local.env_file)
    DISABLE_USERPASS_LOGIN      = provider::dotenv::get_by_key("ROMM_DISABLE_LOCAL_LOGIN", local.env_file)
    OIDC_ENABLED                = provider::dotenv::get_by_key("ROMM_OIDC_ENABLED", local.env_file)
    OIDC_AUTOLOGIN              = provider::dotenv::get_by_key("ROMM_OIDC_AUTOLOGIN", local.env_file)
    DISABLE_USERPASS_LOGIN      = provider::dotenv::get_by_key("ROMM_OIDC_PREVENT_LOCAL_LOGIN", local.env_file)
    OIDC_PROVIDER               = "authentik"
    OIDC_CLIENT_ID              = provider::dotenv::get_by_key("ROMM_OIDC_CLIENT_ID", local.env_file)
    OIDC_CLIENT_SECRET          = provider::dotenv::get_by_key("ROMM_OIDC_CLIENT_SECRET", local.env_file)
    OIDC_SERVER_APPLICATION_URL = provider::dotenv::get_by_key("ROMM_OIDC_CLIENT_URL", local.env_file)
    OIDC_REDIRECT_URI           = provider::dotenv::get_by_key("ROMM_OIDC_REDIRECT_URL", local.env_file)
    OIDC_CLAIM_ROLES            = provider::dotenv::get_by_key("ROMM_OIDC_CLAIM_ROLES", local.env_file)
    OIDC_ROLE_VIEWER            = provider::dotenv::get_by_key("ROMM_OIDC_ROLE_USER", local.env_file)
    OIDC_ROLE_ADMIN             = provider::dotenv::get_by_key("ROMM_OIDC_ROLE_ADMIN", local.env_file)
    ROMM_BASE_URL               = provider::dotenv::get_by_key("ROMM_BASE_URL", local.env_file)
  }

  postgres_env_vars = {
    POSTGRES_PASSWORD = provider::dotenv::get_by_key("ROMM_POSTGRESQL_PASSWORD", local.env_file)
    POSTGRES_USER     = provider::dotenv::get_by_key("ROMM_POSTGRESQL_USER", local.env_file)
    POSTGRES_DB       = provider::dotenv::get_by_key("ROMM_POSTGRESQL_DB", local.env_file)
  }
}

module "romm_network" {
  source = "../../01-networking/network-service"
  name   = "romm-network"
  subnet = "172.17.0.8/29"
  driver = "bridge"
  options = {
    "isolate" : false
  }
}


module "romm-postgres" {
  source         = "../../10-generic/docker-service"
  container_name = local.postgres_container_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
  networks       = [module.romm_network.name]
}

module "romm-valkey" {
  source         = "../../10-generic/docker-service"
  container_name = local.valkey_container_name
  image          = local.valkey_image
  tag            = local.valkey_tag
  volumes        = local.redis_volumes
  networks       = [module.romm_network.name]
}

module "romm" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.container_image
  tag            = local.container_tag
  env_vars       = local.romm_env_vars
  volumes        = local.romm_volumes
  networks       = concat([module.romm_network.name], var.networks)
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["romm"]
  }
}
