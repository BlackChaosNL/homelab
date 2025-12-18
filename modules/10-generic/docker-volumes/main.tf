module "system_globals" {
  source = "../../00-globals/system"
}

terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
    name = var.temporary_volume
}

resource "docker_volume" "shared_volume" {
    name = local.name
}