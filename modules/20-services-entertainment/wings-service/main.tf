terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name = "pelican-wings"
  wings_image    = "ghcr.io/pelican-dev/wings"
  wings_tag      = var.image_tag
  env_file       = "${path.module}/.env"
  internal_port  = 8080

  wing_0_config = <<-EOT
  debug: false
  uuid: ${provider::dotenv::get_by_key("WINGS_0_UUID", local.env_file)}
  token_id: ${provider::dotenv::get_by_key("WINGS_0_TOKEN_ID", local.env_file)}
  token: ${provider::dotenv::get_by_key("WINGS_0_TOKEN", local.env_file)}
  api:
    host: 0.0.0.0
    port: 8080
    ssl:
      enabled: false
      cert: /etc/letsencrypt/live/games.blackchaosnl.myaddr.dev/fullchain.pem
      key: /etc/letsencrypt/live/games.blackchaosnl.myaddr.dev/privkey.pem
    upload_limit: 256
  system:
    data: /var/lib/pelican/volumes
    sftp:
      bind_port: 2022
  allowed_mounts: []
  remote: 'https://gpanel.blackchaosnl.myaddr.dev'
  EOT
}

resource "local_file" "wing_0_config_file" {
  content  = local.wing_0_config
  filename = "${var.volume_path}/${local.container_name}/wing-0-config.yml"
}

module "wings_network" {
  source = "../../../01-networking/docker-network"

  name       = "pelican-wings"
  driver     = "bridge"
  attachable = true
  subnet     = "172.17.0.0/16"
  options = {
    "com.docker.network.bridge.name" = "pelican-wings"
  }
}


module "pelican-wings" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.wings_image
  tag            = local.wings_tag
  networks       = concat([var.wings_network.name], var.networks)
  restart_policy = "always"
  ports = [
    {
      internal = 8080
      external = 8080
      protocol = "tcp"
    },
    {
      internal = 2022
      external = 2022
      protocol = "tcp"
    }
  ]
  volumes = [
    {
      host_path      = "/run/user/1000/podman/podman.sock"
      container_path = "/var/run/docker.sock"
      read_only      = false
    },
    {
      host_path      = "/home/jjvij/.local/share/containers/"
      container_path = "/var/lib/docker/containers/"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/wing-0-config.yml"
      container_path = "/etc/pelican/config.yml"
      read_only      = false
    }
  ]
  env_vars = {
    TZ             = var.timezone
    APP_TIMEZONE   = var.timezone
    WINGS_UID      = var.user_id
    WINGS_GID      = var.group_id
    WINGS_USERNAME = "pelican"
  }
  userns_mode = "keep-id:uid=1000,gid=1000"
  labels = {
    "run.oci.keep_original_groups" = "1"
  }
  security_opts = [
    "label:type:container_runtype_t"
  ]
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["games"]
  }
}