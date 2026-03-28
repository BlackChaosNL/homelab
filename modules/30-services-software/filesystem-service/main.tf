terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name            = "fs-quantum"
  fs_image                  = "ghcr.io/gtstef/filebrowser"
  fs_tag                    = var.image_tag
  env_file                  = "${path.module}/.env"
  internal_port             = 80

  fs_env_vars = {
    PUID                           = var.user_id
    PGID                           = var.group_id
    TZ                             = var.timezone
    PORT                           = 80
    FILEBROWSER_OIDC_CLIENT_ID     = provider::dotenv::get_by_key("FILEBROWSER_OIDC_CLIENT_ID", local.env_file)
    FILEBROWSER_OIDC_CLIENT_SECRET = provider::dotenv::get_by_key("FILEBROWSER_OIDC_CLIENT_SECRET", local.env_file)
  }

  fs_settings = <<-EOT
  server:
    sources:
      - path: "/black"
        config:
          defaultEnabled: false
      - path: "/blue"
        config:
          defaultEnabled: false
  auth:
    methods:
        oidc:
          enabled: true
          issuerUrl: "https://authz.blackchaosnl.myaddr.dev/application/o/fs/"
          scopes: "email openid profile groups"
          userIdentifier: "preferred_username"
          createUser: true
          userGroups: "user"
          adminGroup: "admin"
          groupsClaim: "groups"
        password:
          enabled: false
          signup: false
  EOT
}

resource "local_file" "fs_config_file" {
  content  = local.fs_settings
  filename = "${var.volume_path}/${local.container_name}/config.yaml"
}

module "fs-quantum" {
    source = "../../10-generic/docker-service"
    container_name = local.container_name
    image          = local.fs_image
    tag            = local.fs_tag
    volumes        = [
    {
      host_path      = "/mnt/storage"
      container_path = "/black"
      read_only      = false
    },
    {
      host_path      = "/mnt/ssd"
      container_path = "/blue"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/config.yaml"
      container_path = "/home/filebrowser/data/config.yaml"
      read_only      = true
    }
  ]
  env_vars       = local.fs_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["fs"]
  }
}