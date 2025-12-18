output "id" {
    description = "ID of the temporary volume"
    value       = docker_volume.shared_volume.id
}

output "name" {
    description = "Name of the temporary volume"
    value       = docker_volume.shared_volume.name
}