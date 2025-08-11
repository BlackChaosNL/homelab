output "services" {
  description = "Service definitions for all services"
  value = [
    for service in module.services.service_definitions : {
      name     = service.name
      endpoint = service.endpoint
    }
  ]
}