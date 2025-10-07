output "service_definitions" {
  description = "Service definitions for all services"
  value = [
    module.jellyfin.service_definition,
    module.calibre.service_definition,
    module.pelican.service_definition,
    module.authentik.service_definition,
    module.traccar.service_definition,
    module.tandoor.service_definition,
    module.qbittorrent.service_definition,
    module.coder.service_definition,
    module.actualbudget.service_definition,
  ]
}

output "infrastructure_int" {
  description = "The internal infrastructure network"
  value = module.infrastructure_int
}