locals {
  module_dir  = "../modules"
  root_volume = module.system_globals.volume_host
  volume_host = "${module.system_globals.volume_host}/appconfig"
}

module "system_globals" {
  source = "${local.module_dir}/00-globals/system"
}

module "homelab_docker_network" {
  source     = "${local.module_dir}/01-networking/network-service"
  name       = "blue"
  driver     = "bridge"
  attachable = true
  subnet     = "10.88.0.0/16"
}

module "authentik" {
  source = "${local.module_dir}/30-services-software/authentik-service"
  volume_path = "${local.root_volume}/authentik"
  networks = [
    module.homelab_docker_network.name
  ]
}

module "jellyfin" {
  source = "${local.module_dir}/20-services-entertainment/jellyfin-service"
  volume_path = "${local.root_volume}/jellyfin"
  networks = [
    module.homelab_docker_network.name
  ]
}