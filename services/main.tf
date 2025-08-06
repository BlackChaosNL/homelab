locals {
  module_dir  = "../modules"
  root_volume = module.system_globals.volume_host
  volume_host = "${module.system_globals.volume_host}/appconfig"
}

module "system_globals" {
  source = "${local.module_dir}/00-globals/system"
}

module "homelab_docker_network" {
  source = "${local.module_dir}/01-networking/docker-network"
  name       = "default"
  driver     = "bridge"
  attachable = true
  subnet     = "10.88.0.0/16"
}