terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  container_name = "anubis"
  image          = "ghcr.io/techarohq/anubis"
  tag            = var.image_tag
  volumes = [
    {
      host_path      = "./${path.module}/botPolicies.yaml"
      container_path = "/etc/anubis/botPolicies.yaml"
      read_only      = true
    },
  ]
  env_vars = {
    BIND        = ":3000"
    TARGET      = "http://10.100.0.1:8080"
    POLICY_FILE = "/etc/anubis/botPolicies.yaml"
  }
}

module "anubis" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  env_vars       = local.env_vars
  volumes        = local.volumes
  ports = [
    {
      internal = 3000
      external = 3333
      protocol = "tcp"
    }
  ]
  restart_policy = "always"
}
