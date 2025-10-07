terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name         = "pelican"
  wings_container_name   = "pelican-wings"
  pelican_image          = "ghcr.io/pelican-dev/panel"
  pelican_wings_image    = "ghcr.io/pelican-dev/wings"
  pelican_tag            = var.image_tag
  pelican_wings_tag      = var.wings_image_tag
  env_file               = "${path.module}/.env"
  pelican_internal_port  = 80

  caddyfile_content = <<-EOT
  {
    admin off
    auto_https disable_certs
    email none@none.invalid
  }

  :80 {
    root * /var/www/html/public
    encode gzip

    php_fastcgi 127.0.0.1:9000
    file_server
  }
  EOT
}

resource "local_file" "pelican_caddy_config_file" {
    content  = local.caddyfile_content
    filename = "${var.volume_path}/${local.container_name}/Caddyfile"
}

module "pelican_network" {
  source = "../../01-networking/network-service"
  name   = "pelican-network"
  subnet = "172.16.0.8/29"
  driver = "bridge"
  options = {
    "isolate": false
  }
}

module "pelican-panel" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.pelican_image
  tag            = local.pelican_tag
  networks       = concat([module.pelican_network.name], var.networks)
  restart_policy = "always"
  userns_mode    = "keep-id:auto"
  volumes        = [
    {
        host_path = "${var.volume_path}/${local.container_name}/data"
        container_path = "/pelican-data"
        read_only = false
    },
    {
        host_path = "${var.volume_path}/${local.container_name}/logs"
        container_path = "/var/www/html/storage/logs"
        read_only = false
    },
    {
        host_path = "${var.volume_path}/${local.container_name}/Caddyfile"
        container_path = "/etc/caddy/Caddyfile"
        read_only = true
    }
  ]
  env_vars       = {
    TZ           = var.timezone
    PUID         = var.user_id
    PGID         = var.group_id
    APP_TIMEZONE = var.timezone
    APP_ENV      = "production"
    APP_URL      = "${var.subdomain}.blackchaosnl.myaddr.dev"
    ADMIN_EMAIL  = "jjvijgen@gmail.com"
  }
}

module "pelican-wings" {
  source         = "../../10-generic/docker-service"
  container_name = local.wings_container_name
  image          = local.pelican_wings_image
  tag            = local.pelican_wings_tag
  networks       = concat([module.pelican_network.name], var.networks)
  restart_policy = "always"
  volumes        = [
    {
      host_path = "/run/user/1000/podman/podman.sock"
      container_path = "/var/run/docker.sock"
      read_only = false
    },
    {
      host_path = "/home/jjvij/.local/share/containers"
      container_path = "/var/lib/docker/containers/"
      read_only = false
    }
  ]
  env_vars = {
    TZ               = var.timezone
    APP_TIMEZONE     = var.timezone
    WINGS_UID        = var.user_id
    WINGS_GID        = var.group_id
    WINGS_USERNAME   = "pelican"
  }
  userns_mode    = "keep-id:uid=1000,gid=1000"
  labels         = {
    "run.oci.keep_original_groups" = "1"
  }
  security_opts  = [
    "label:type:container_runtype_t"
  ]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.pelican_internal_port
    endpoint     = "http://${local.container_name}:${local.pelican_internal_port}"
    subdomain    = [var.subdomain]
  }
}
