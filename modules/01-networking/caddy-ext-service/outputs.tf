output "container_name" {
  description = "The name of the deployed Caddy container"
  value       = module.caddy.container_name
}

output "config_hash" {
  description = "The SHA256 hash of the generated Caddyfile content"
  value       = sha256(local.caddyfile_default)
}