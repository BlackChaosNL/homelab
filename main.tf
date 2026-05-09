module "system_globals" {
  source = "./modules/00-globals/system"
}

module "services" {
  source = "./services"
}

locals {
  volume_host = module.system_globals.volume_host
}

module "caddy-ext" {
  source      = "./modules/01-networking/caddy-ext-service"
  volume_path = local.volume_host
  tls_email   = "jjvijgen@gmail.com"
  domains     = [
    "blackchaosnl.myaddr.dev",
  ]
  service_definitions = module.services.service_definitions
}

module "anubis" {
  source = "./modules/01-networking/anubis-service"
}

module "caddy-int" {
  source      = "./modules/01-networking/caddy-int-service"
  volume_path = local.volume_host
  domains     = [
    "blackchaosnl.myaddr.dev",
  ]
  service_definitions = module.services.service_definitions
  networks    = [
    module.services.infrastructure_int.name
  ]
}
