terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name           = "freeipa"
  freeipa_image             = "quay.io/repository/freeipa/freeipa-server"
  freeipa_tag               = var.image_tag
  env_file                 = "${path.module}/.env"
  freeipa_internal_port     = 8443

  freeipa_volumes = [
    {
      host_path  = "${var.volume_path}/${local.container_name}/data"
      container_path  = "${var.volume_path}/${local.container_name}/data"
    },
    {
      host_path  = ""
      container_path  = "${var.volume_path}/${local.container_name}/data"

    }
  ]

  freeipa_env_vars = {
    PASSWORD          = var.admin_password
  }
}

module "freeipa" {
  source         = "../../10-services-generic/docker-service"
  container_name = local.container_name
  image          = local.freeipa_image
  tag            = local.freeipa_tag
  volumes        = local.freeipa_volumes
  env_vars       = local.freeipa_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.freeipa_internal_port
    endpoint     = "http://${local.container_name}:${local.freeipa_internal_port}"
    subdomains   = ["ipa"]
    ports        = [
      {
        external = 8080
        internal = 80
        protocol = "tcp"
      },
      {
        external = 8443
        internal = 443
        protocol = "tcp"
      }
    ]
  }
}