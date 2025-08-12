module "system_globals" {
  source = "./modules/00-globals/system"
}

module "services" {
  source = "./services"
}

locals {
  volume_host = "${module.system_globals.volume_host}"
}

module "caddy" {
  source              = "./modules/01-networking/caddy-service"
  volume_path         = "${local.volume_host}"
  domains             = [
    "blackchaosnl.duckdns.org",
    "blackchaosnl.myaddr.io",
    "blackchaosnl.myaddr.dev",
    "blackchaosnl.myaddr.tools"
  ]
  tls_email           = "jjvijgen@gmail.com"
  container_name      = "caddy"
  service_definitions = module.services.service_definitions
  networks            = [
    "blue"
  ]
}