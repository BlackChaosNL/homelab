locals {
  module_dir  = "../modules"
  root_volume = module.system_globals.volume_host
  volume_host = "${module.system_globals.volume_host}/appconfig"
}

module "system_globals" {
  source = "${local.module_dir}/00-globals/system"
}

module "infrastructure_int" {
  source     = "../modules/01-networking/network-service"
  name       = "infrastructure_int"
  subnet     = "172.16.0.0/12"
  driver     = "bridge"
  attachable = true
  options = {
    "isolate" : false
  }
}

module "jellyfin" {
  source      = "${local.module_dir}/20-services-entertainment/jellyfin-service"
  volume_path = "${local.root_volume}/jellyfin"
  networks    = [module.infrastructure_int.name]
}

module "authentik" {
  source      = "${local.module_dir}/30-services-software/authentik-service"
  volume_path = "${local.root_volume}/authentik"
  networks    = [module.infrastructure_int.name]
}

module "traccar" {
  source      = "${local.module_dir}/30-services-software/traccar-service"
  volume_path = "${local.root_volume}/traccar"
  networks    = [module.infrastructure_int.name]
}

module "tandoor" {
  source      = "${local.module_dir}/30-services-software/tandoor-service"
  volume_path = "${local.root_volume}/tandoor"
  networks    = [module.infrastructure_int.name]
}

module "coder" {
  source      = "${local.module_dir}/30-services-software/coder-service"
  volume_path = "${local.root_volume}/coder"
  networks    = [module.infrastructure_int.name]
}

module "penpot" {
  source      = "${local.module_dir}/30-services-software/penpot-service"
  volume_path = "${local.root_volume}/penpot"
  networks    = [module.infrastructure_int.name]
}