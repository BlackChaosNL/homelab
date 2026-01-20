terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

module "vol" {
  source = "../../10-generic/docker-volumes"
  name = "penpot_temp"
}

locals {
  container_name          = "penpot"
  penpot_backend_name     = "penpot-backend"
  penpot_exporter_name    = "penpot-exporter"
  postgres_container_name = "penpot-postgres"
  valkey_container_name   = "penpot-valkey"
  penpot_frontend_image   = "docker.io/penpotapp/frontend"
  penpot_backend_image    = "docker.io/penpotapp/backend"
  penpot_exporter_image   = "docker.io/penpotapp/exporter"
  valkey_image            = "docker.io/valkey/valkey"
  postgres_image          = "docker.io/library/postgres"
  penpot_frontend_tag     = var.image_tag
  penpot_backend_tag      = var.image_tag
  penpot_exporter_tag     = var.image_tag
  valkey_tag              = var.valkey_image_tag
  postgres_tag            = var.postgres_image_tag
  env_file                = "${path.module}/.env"
  internal_port           = 8080
  USER_ID                 = var.user_id
  GROUP_ID                = var.group_id


  penpot_volumes = [
    {
      host_path      = "${module.vol.host_path}"
      container_path = "/opt/data/assets"
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

  penpot_exporter_env_vars = {
    PENPOT_SECRET_KEY = provider::dotenv::get_by_key("PENPOT_SECRET_KEY", local.env_file)
    PENPOT_PUBLIC_URI = "http://${local.container_name}:${local.internal_port}"
    PENPOT_REDIS_URI  = "redis://${local.valkey_container_name}/0"
  }

  # Disable emails and enable OIDC since this is a private instanced managed with Authentik
  penpot_frontend_env_vars = {
    PENPOT_FLAGS = "disable-registration disable-email-verification disable-smtp enable-prepl-server enable-login-with-oidc"
    USER_ID=local.USER_ID
    GROUP_ID=local.GROUP_ID
  }

  penpot_backend_env_vars = {
    PENPOT_SECRET_KEY = provider::dotenv::get_by_key("PENPOT_SECRET_KEY", local.env_file)

    PENPOT_PREPL_HOST = "0.0.0.0"

    PENPOT_DATABASE_URI      = "postgresql://${local.postgres_container_name}/${try(provider::dotenv::get_by_key("POSTGRES_DB", local.env_file), "penpot")}"
    PENPOT_DATABASE_USERNAME = provider::dotenv::get_by_key("POSTGRES_USER", local.env_file)
    PENPOT_DATABASE_PASSWORD = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
    PENPOT_REDIS_URI         = "redis://${local.valkey_container_name}/0"

    PENPOT_OBJECTS_STORAGE_BACKEND      = "fs"
    PENPOT_OBJECTS_STORAGE_FS_DIRECTORY = "/opt/data/assets"

    PENPOT_TELEMETRY_ENABLED = false
    PENPOT_TELEMETRY_REFERER = ""

    PENPOT_OIDC_CLIENT_ID = provider::dotenv::get_by_key("PENPOT_OIDC_CLIENT_ID", local.env_file)
    PENPOT_OIDC_CLIENT_SECRET = provider::dotenv::get_by_key("PENPOT_OIDC_CLIENT_SECRET", local.env_file)
    PENPOT_OIDC_BASE_URI  = provider::dotenv::get_by_key("PENPOT_OIDC_BASE_URI", local.env_file)
    PENPOT_OIDC_ROLES     = provider::dotenv::get_by_key("PENPOT_OIDC_ROLES", local.env_file)
  }

  postgres_env_vars = {
    POSTGRES_USER     = provider::dotenv::get_by_key("POSTGRES_USER", local.env_file)
    POSTGRES_PASSWORD = provider::dotenv::get_by_key("POSTGRES_PASSWORD", local.env_file)
    POSTGRES_DB       = provider::dotenv::get_by_key("POSTGRES_DB", local.env_file)
  }
}

module "penpot_network" {
  source = "../../01-networking/network-service"
  name   = "penpot-network"
  subnet = "172.16.0.32/29"
  driver = "bridge"
  options = {
    "isolate" : false
  }
}

module "penpot-postgres" {
  source         = "../../10-generic/docker-service"
  container_name = local.postgres_container_name
  image          = local.postgres_image
  tag            = local.postgres_tag
  volumes        = local.postgres_volumes
  env_vars       = local.postgres_env_vars
  networks       = [module.penpot_network.name]
  restart_policy = "always"
}

module "penpot-valkey" {
  source         = "../../10-generic/docker-service"
  container_name = local.valkey_container_name
  image          = local.valkey_image
  tag            = local.valkey_tag
  networks       = [module.penpot_network.name]
  restart_policy = "always"
}

module "penpot-exporter" {
  source         = "../../10-generic/docker-service"
  container_name = local.penpot_exporter_name
  image          = local.penpot_exporter_image
  tag            = local.penpot_backend_tag
  env_vars       = local.penpot_exporter_env_vars
  networks       = [module.penpot_network.name]
  restart_policy = "always"
}

module "penpot-backend" {
  source         = "../../10-generic/docker-service"
  container_name = local.penpot_backend_name
  image          = local.penpot_backend_image
  tag            = local.penpot_backend_tag
  volumes        = local.penpot_volumes
  env_vars       = merge(local.penpot_frontend_env_vars, local.penpot_backend_env_vars)
  networks       = [module.penpot_network.name]
  restart_policy = "always"
}

module "penpot" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.penpot_frontend_image
  tag            = local.penpot_frontend_tag
  volumes        = local.penpot_volumes
  env_vars       = local.penpot_frontend_env_vars
  networks       = concat([module.penpot_network.name], var.networks)
  restart_policy = "always"
}


output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["penpot"]
  }
}
