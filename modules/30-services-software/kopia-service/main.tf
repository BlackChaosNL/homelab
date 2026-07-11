terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name = "kopia"
  image          = "docker.io/kopia/kopia"
  tag            = var.image_tag
  env_file       = "${path.module}/.env"
  internal_port  = 51515

  env_vars = {
    TZ = var.timezone
    USER = provider::dotenv::get_by_key("KOPIA_USER", local.env_file)
    KOPIA_PASSWORD = provider::dotenv::get_by_key("KOPIA_PASSWORD", local.env_file)
  }
}

module "kopia" {
    source         = "../../10-generic/docker-service"
    container_name = local.container_name
    image          = local.image
    tag            = local.tag
    volumes        = [
        {
            host_path = "${var.volume_path}/${local.container_name}/rclone"
            container_path = "/app/rclone/"
            read_only = false
        },
        {
            host_path = "${var.volume_path}/${local.container_name}/config"
            container_path = "/app/config"
            read_only = false
        },
        {
            host_path = "${var.volume_path}/${local.container_name}/cache"
            container_path = "/app/cache"
            read_only = false
        },
        {
            host_path = "${var.volume_path}/${local.container_name}/logs"
            container_path = "/app/logs"
            read_only = false
        },
        {
            host_path = "${var.volume_path}/${local.container_name}/repositories"
            container_path = "/repository"
            read_only = false
        },
        {
            host_path = "${var.volume_path}/${local.container_name}/tmp"
            container_path = "/tmp"
            read_only = false
        },
        {
            host_path = "/home/jjvij/homelab/appdata"
            container_path = "/appdata"
            read_only = true
        },
    ]
    env_vars       = local.env_vars
    networks       = concat(var.networks)
    restart_policy = "always"
    command = [ "server",
                "start", 
                "--disable-csrf-token-checks",
                "--insecure",
                "--address=0.0.0.0:51515",
                "--server-username=${provider::dotenv::get_by_key("KOPIA_USER", local.env_file)}",
                "--server-password=${provider::dotenv::get_by_key("KOPIA_PASSWORD", local.env_file)}" ]
}


output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.internal_port
    endpoint     = "http://${local.container_name}:${local.internal_port}"
    subdomains   = ["kopia"]
  }
}