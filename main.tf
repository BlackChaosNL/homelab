module "system_globals" {
  source = "./modules/00-globals/system"
}

// Application services
module "services" {
  source = "./services"
}

locals {
  volume_host = "${module.system_globals.volume_host}/appdata"
}

module "caddy" {
  source              = "./modules/01-networking/caddy-service"
  volume_path         = "./docker/infrastructure/"
  domains             = [
    "blackchaosnl.duckdns.org",
    "blackchaosnl.myaddr.io",
    "blackchaosnl.myaddr.dev",
    "blackchaosnl.myaddr.tools"
  ]
  tls_email           = "your-email@example.com"  # For Let's Encrypt
  container_name      = "caddy"
  service_definitions = module.services.service_definitions
  networks            = ["default"]
}