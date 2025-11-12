terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name        = "pelican"
  pelican_image         = "ghcr.io/pelican-dev/panel"
  pelican_tag           = var.image_tag
  env_file              = "${path.module}/.env"
  pelican_internal_port = 8000

  caddyfile_content = <<-EOT
  {
    admin off
    auto_https disable_certs
    email none@none.invalid
  }

  :8000 {
    root * /var/www/html/public
    encode gzip

    php_fastcgi 127.0.0.1:9000
    file_server
  }
  EOT

  pelican_env_file = <<-EOT
  APP_KEY=${provider::dotenv::get_by_key("APP_KEY", local.env_file)}
  APP_INSTALLED=true
  APP_NAME=Pelican
  APP_URL="https://gpanel.blackchaosnl.myaddr.dev"

  DB_CONNECTION=sqlite
  DB_DATABASE="database.sqlite"

  CACHE_STORE=file

  QUEUE_CONNECTION=database

  SESSION_DRIVER=file
  EOT
}


resource "local_file" "pelican_caddy_config_file" {
  content  = local.caddyfile_content
  filename = "${var.volume_path}/${local.container_name}/Caddyfile"
}

resource "local_file" "pelican_config_file" {
  content  = local.pelican_env_file
  filename = "${var.volume_path}/${local.container_name}/.env"
}



module "pelican-panel" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.pelican_image
  tag            = local.pelican_tag
  networks       = var.networks
  restart_policy = "always"
  volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/Caddyfile"
      container_path = "/etc/caddy/Caddyfile"
      read_only      = true
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/.env"
      container_path = "/pelican-data/.env"
      read_only      = true
    }
  ]
  env_vars = {
    TZ           = var.timezone
    PUID         = var.user_id
    PGID         = var.group_id
    APP_TIMEZONE = var.timezone
    APP_ENV      = "production"
    APP_URL      = "https://gpanel.blackchaosnl.myaddr.dev"
    ADMIN_EMAIL  = "jjvijgen@gmail.com"
  }
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.pelican_internal_port
    endpoint     = "http://${local.container_name}:${local.pelican_internal_port}"
    subdomains   = ["gpanel"]
  }
}
