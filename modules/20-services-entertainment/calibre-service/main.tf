terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name         = "calibre"
  calibre_image          = "docker.io/crocodilestick/calibre-web-automated"
  calibre_tag            = var.image_tag
  calibre_internal_port  = 8083

  calibre_volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/config"
      container_path = "/config"
      read_only      = false
    },{
      host_path      = "${var.volume_path}/${local.container_name}/book-ingest"
      container_path = "/cwa-book-ingest"
      read_only      = false
    },{
      host_path      = "${var.volume_path}/${local.container_name}/Calibre Library"
      container_path = "/calibre-library"
      read_only      = false
    },{
      host_path      = "${var.volume_path}/${local.container_name}/plugins"
      container_path = "/config/.config/calibre/plugins"
      read_only      = false
    },
  ]

  calibre_env_vars = {
    PUID        = var.user_id
    PGID        = var.group_id
    TZ          = var.timezone
  }
}

module "calibre" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.calibre_image
  tag            = local.calibre_tag
  volumes        = local.calibre_volumes
  env_vars       = local.calibre_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.calibre_internal_port
    endpoint     = "http://${local.container_name}:${local.calibre_internal_port}"
    subdomains   = ["books"]
    is_guarded   = true
  }
}