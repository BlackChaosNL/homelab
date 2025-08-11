output "service_definitions" {
  description = "Service definitions for all services"
  value = [
    module.jellyfin.service_definition,
    module.lldap.service_definition,
    module.authentik.service_definition,
  ]
}

output "homelab_docker_network_name" {
  description = "The name of the Docker network"
  value       = module.homelab_docker_network.name
}