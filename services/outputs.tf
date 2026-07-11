output "service_definitions" {
  description = "Service definitions for all services"
  value = [
    module.jellyfin.service_definition,
    module.authentik.service_definition,
    module.tandoor.service_definition,
    module.coder.service_definition,
    module.gitea.service_definition,
    module.vaultwarden.service_definition,
    module.kopia.service_definition,
  ]
}

output "infrastructure_int" {
  description = "The internal infrastructure network"
  value       = module.infrastructure_int
}