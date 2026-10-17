terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name          = "dawarich"
  sidekiq_container_name  = "dawarich-sidekiq"
  postgis_container_name  = "dawarich-postgis"
  valkey_container_name   = "dawarich-valkey"
  container_image         = "docker.io/freikin/dawarich"
  postgis_image           = "docker.io/postgis/postgis"
  valkey_image            = "docker.io/valkey/valkey"
  container_tag           = var.image_tag
  postgis_tag             = var.postgis_image_tag
  valkey_tag              = var.valkey_image_tag
  env_file                = "${path.module}/.env"
  internal_port           = 3000

  dawarich_volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/dawarich/public"
      container_path = "/var/app/public"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/dawarich/watched"
      container_path = "/var/app/tmp/imports/watched"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/dawarich/storage"
      container_path = "/var/app/storage"
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

  postgis_volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/postgres/data"
      container_path = "/var/lib/postgresql/data"
      read_only      = false
    },
  ]

  dawarich_common_env_vars = {
    RAILS_ENV                         = "production"
    REDIS_URL                         = "redis://${local.valkey_container_name}:6379"
    DATABASE_HOST                     = "${local.postgis_container_name}"
    DATABASE_PORT                     = 5432
    DATABASE_USERNAME                 = provider::dotenv::get_by_key("DAWARICH_POSTGRES_USER", local.env_file)
    DATABASE_PASSWORD                 = provider::dotenv::get_by_key("DAWARICH_POSTGRES_PASSWORD", local.env_file)
    DATABASE_NAME                     = provider::dotenv::get_by_key("DAWARICH_POSTGRES_DB", local.env_file)
    APPLICATION_HOSTS                 = provider::dotenv::get_by_key("DAWARICH_APPLICATION_HOSTS", local.env_file)
    TIME_ZONE                         = var.timezone
    SECRET_KEY_BASE                   = provider::dotenv::get_by_key("DAWARICH_SECRET_KEY", local.env_file)
    SELF_HOSTED                       = true
    STORE_GEODATA                     = true
    APPLICATION_PROTOCOL              = "https"
    DOMAIN                            = "maps.blackchaosnl.myaddr.dev"
    RAILS_LOG_TO_STDOUT               = true
    PROMETHEUS_EXPORTER_ENABLED       = false
    OIDC_CLIENT_ID                    = provider::dotenv::get_by_key("DAWARICH_OIDC_CLIENT_ID", local.env_file)
    OIDC_CLIENT_SECRET                = provider::dotenv::get_by_key("DAWARICH_OIDC_CLIENT_SECRET", local.env_file)
    OIDC_ISSUER                       = provider::dotenv::get_by_key("DAWARICH_OIDC_ISSUER", local.env_file)
    OIDC_REDIRECT_URI                 = provider::dotenv::get_by_key("DAWARICH_OIDC_REDIRECT_URI", local.env_file)
    OIDC_PROVIDER_NAME                = provider::dotenv::get_by_key("DAWARICH_OIDC_PROVIDER_NAME", local.env_file)
    OIDC_AUTO_REGISTER                = provider::dotenv::get_by_key("DAWARICH_OIDC_AUTO_REGISTER", local.env_file)
    ALLOW_EMAIL_PASSWORD_REGISTRATION = provider::dotenv::get_by_key("DAWARICH_ALLOW_EMAIL_PASSWORD_REGISTRATION", local.env_file)
    ALLOW_EMAIL_PASSWORD_LOGIN        = provider::dotenv::get_by_key("DAWARICH_ALLOW_EMAIL_PASSWORD_LOGIN", local.env_file)
  }

  dawarich_env_vars = {
    WEB_CONCURRENCY = 1
  }

  dawarich_sidekiq_env_vars = {
    BACKGROUND_PROCESSING_CONCURRENCY = 3
  }

  postgis_env_vars = {
    POSTGRES_USER     = provider::dotenv::get_by_key("DAWARICH_POSTGRES_USER", local.env_file)
    POSTGRES_PASSWORD = provider::dotenv::get_by_key("DAWARICH_POSTGRES_PASSWORD", local.env_file)
    POSTGRES_DB       = provider::dotenv::get_by_key("DAWARICH_POSTGRES_DB", local.env_file)
  }

  postgis_settings = <<-EOT
  # TYPE  DATABASE        USER            ADDRESS                 METHOD
  # "local" is for Unix domain socket connections only
  local   all             all                                     trust
  # IPv4 local connections:
  host    all             all             172.17.0.32/29          trust
  # IPv6 local connections:
  host    all             all             ::1/128                 trust
  # Allow replication connections from localhost, by a user with the
  # replication privilege.
  local   replication     all                                     trust
  host    replication     all             127.0.0.1/32            trust
  host    replication     all             ::1/128                 trust
  EOT
}

resource "local_file" "caddyfile" {
  content  = local.postgis_settings
  filename = "${var.volume_path}/${local.container_name}/postgres/data/pg_hba.conf"
}

module "dawarich_network" {
  source = "../../01-networking/network-service"
  name   = "dawarich-network"
  subnet = "172.17.0.32/29"
  driver = "bridge"
  options = {
    "isolate" : false
  }
}

module "dawarich-postgis" {
  source         = "../../10-generic/docker-service"
  container_name = local.postgis_container_name
  image          = local.postgis_image
  tag            = local.postgis_tag
  volumes        = local.postgis_volumes
  env_vars       = local.postgis_env_vars
  networks       = [module.dawarich_network.name]
}

module "dawarich-valkey" {
  source         = "../../10-generic/docker-service"
  container_name = local.valkey_container_name
  image          = local.valkey_image
  tag            = local.valkey_tag
  volumes        = local.redis_volumes
  networks       = [module.dawarich_network.name]
}

module "dawarich-sidekiq" {
  source         = "../../10-generic/docker-service"
  container_name = local.sidekiq_container_name
  image          = local.container_image
  tag            = local.container_tag
  volumes        = local.dawarich_volumes
  env_vars       = merge(local.dawarich_common_env_vars, local.dawarich_sidekiq_env_vars)
  networks       = [module.dawarich_network.name]
  entrypoint     = [ "sidekiq-entrypoint.sh" ]
  command        = [ "sidekiq" ]
}

module "dawarich" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.container_image
  tag            = local.container_tag
  volumes        = local.dawarich_volumes
  env_vars       = merge(local.dawarich_common_env_vars, local.dawarich_env_vars)
  networks       = concat([module.dawarich_network.name], var.networks)
  entrypoint     = [ "sidekiq-entrypoint.sh" ]
  command        = [ "bin/rails server -p 3000 -b ::" ]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["maps"]
  }
}
