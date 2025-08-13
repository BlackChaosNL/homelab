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
  subnet     = "10.100.0.0/24"
  driver     = "bridge"
  attachable = true
}

module "authentik" {
  source = "${local.module_dir}/30-services-software/authentik-service"
  volume_path = "${local.root_volume}/authentik"
  networks = [module.infrastructure_int.name]
}

module "traccar" {
  source = "${local.module_dir}/30-services-software/traccar-service"
  volume_path = "${local.root_volume}/traccar"
  networks = [module.infrastructure_int.name]
}

module "tandoor" {
  source = "${local.module_dir}/30-services-software/tandoor-service"
  volume_path = "${local.root_volume}/tandoor"
  networks = [module.infrastructure_int.name]
}

module "jellyfin" {
  source = "${local.module_dir}/20-services-entertainment/jellyfin-service"
  volume_path = "${local.root_volume}/jellyfin"
  networks = [module.infrastructure_int.name]
}

module "qbittorrent" {
  source = "${local.module_dir}/30-services-software/qbittorrent-service"
  volume_path = "${local.root_volume}/qbittorrent"
  networks = [module.infrastructure_int.name]
}

module "coder" {
  source = "${local.module_dir}/30-services-software/coder-service"
  volume_path = "${local.root_volume}/coder"
  networks = [module.infrastructure_int.name]
}

module "calibre" {
  source = "${local.module_dir}/20-services-entertainment/calibre-service"
  volume_path = "${local.root_volume}/calibre"
  networks = [module.infrastructure_int.name]
}
