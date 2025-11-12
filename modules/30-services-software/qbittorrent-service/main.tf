terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name            = "qbittorrent"
  qbittorrent_image         = "lscr.io/linuxserver/qbittorrent"
  qbittorrent_tag           = var.image_tag
  env_file                  = "${path.module}/.env"
  qbittorrent_internal_port = 9080

  qbittorrent_volumes = [
    {
      host_path      = "/mnt/storage/media"
      container_path = "/downloads"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/config"
      container_path = "/config"
      read_only      = false
    }
  ]

  qbittorrent_env_vars = {
    PUID            = var.user_id
    PGID            = var.group_id
    TZ              = var.timezone
    WEBUI_PORT      = provider::dotenv::get_by_key("WEBUI_PORT", local.env_file)
    TORRENTING_PORT = provider::dotenv::get_by_key("TORRENTING_PORT", local.env_file)
  }

}

module "qbittorrent" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.qbittorrent_image
  tag            = local.qbittorrent_tag
  volumes        = local.qbittorrent_volumes
  env_vars       = local.qbittorrent_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.qbittorrent_internal_port
    endpoint     = "http://${local.container_name}:${local.qbittorrent_internal_port}"
    subdomains   = ["downloads"]
    is_guarded   = true
  }
}