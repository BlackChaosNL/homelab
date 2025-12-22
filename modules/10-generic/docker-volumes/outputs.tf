output "name" {
    description = "Name of the temporary volume"
    value       = docker_volume.shared_volume.name
}

output "host_path" {
    description = "Host path of temporary volume mount"
    value       = docker_volume.shared_volume.mountpoint
}