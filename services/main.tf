locals {
  module_dir  = "../modules"
  root_volume = module.system_globals.volume_host
  volume_host = "${module.system_globals.volume_host}/appconfig"
}

module "system_globals" {
  source = "${local.module_dir}/00-globals/system"
}

module "authentik" {
  source = "${local.module_dir}/30-services-software/authentik-service"
  volume_path = "${local.root_volume}/authentik"
  networks = [
    "podman",
  ]
}

module "traccar" {
  source = "${local.module_dir}/30-services-software/traccar-service"
  volume_path = "${local.root_volume}/traccar"
  networks = [
    "podman",
  ]
}

module "tandoor" {
  source = "${local.module_dir}/30-services-software/tandoor-service"
  volume_path = "${local.root_volume}/tandoor"
  networks = [
    "podman",
  ]
}

module "jellyfin" {
  source = "${local.module_dir}/20-services-entertainment/jellyfin-service"
  volume_path = "${local.root_volume}/jellyfin"
  networks = [
    "podman",
  ]
}

module "qbittorrent" {
  source = "${local.module_dir}/30-services-software/qbittorrent-service"
  volume_path = "${local.root_volume}/qbittorrent"
  networks = [
    "podman",
  ]
}

module "coder" {
  source = "${local.module_dir}/30-services-software/coder-service"
  volume_path = "${local.root_volume}/coder"
  networks = [
    "podman",
  ]
}

module "calibre" {
  source = "${local.module_dir}/20-services-entertainment/calibre-service"
  volume_path = "${local.root_volume}/calibre"
  networks = [
    "podman",
  ]
}
