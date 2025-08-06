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
  name       = "default"
  driver     = "bridge"
  attachable = true
  subnet     = "10.88.0.0/16"
}

module "freeipa" {
  source = "${local.module_dir}/30-services-software/lldap-service"
  volume_path = "${local.volume_path}/freeipa"
  networks = [
    module.homelab_docker_network.name
  ]
}

module "jellyfin" {
  source = "${local.module_dir}/20-services-entertainment/jellyfin-service"
  volume_path = "${local.volume_path}/jellyfin"
  networks = [
    module.homelab_docker_network.name
  ]
}