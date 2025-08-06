# Caddy Proxy Module

This module creates a Caddy reverse proxy server that dynamically configures itself based on service definitions passed to it.

## Overview

The Caddy Proxy module:
- Accepts service definitions that specify whether to expose them via reverse proxy
- Dynamically generates Caddyfile configuration from these service definitions
- Supports custom Caddy configuration blocks per service
- Deploys a Caddy container with the generated configuration
- Manages TLS certificates automatically using Let's Encrypt
- Creates DNS records for services with configurable Cloudflare proxying settings

## Usage

### Basic Integration

Add the module to your main Terraform configuration:

```hcl
module "homelab_caddy_proxy" {
  source             = "./modules/01-networking/caddy-proxy"
  domains            = ["yourdomain.com"]
  tls_email          = "your-email@example.com"  # For Let's Encrypt
  container_name     = "caddy-proxy"
  service_definitions = module.services.service_definitions
  networks           = ["your-docker-network"]
}
```

### Service Definition Format

Services should include the following fields to be properly exposed through Caddy:

```hcl
{
  name       = "service-name"
  endpoint   = "service-container:port"
  subdomains = ["app", "dashboard"]  # Will create app.yourdomain.com, dashboard.yourdomain.com
  
  # Option 1: Simplified Caddy configuration via options
  caddy_options = {
    "health_path" = "/health"
    "health_interval" = "30s"
    "header_up X-Real-IP" = "{http.request.remote}"
    # Additional reverse_proxy options as needed
  }
  
  # Option 2: Full custom Caddy configuration (takes precedence if both are provided)
  caddy_config = <<-EOT
    # Raw Caddy configuration goes here
    reverse_proxy /api/* api-backend:8080
    reverse_proxy /* frontend:3000
    header X-Powered-By "My Awesome Homelab"
    log {
      output file /var/log/access.log
    }
  EOT
}
```

## Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `container_name` | The name of the Caddy container | `string` | `""` (generates "caddy-proxy") |
| `image_tag` | The tag of the Caddy Docker image to use | `string` | `"latest"` |
| `domains` | The domain names to use for services | `list(string)` | - |
| `tls_email` | Email address for Let's Encrypt | `string` | - |
| `service_definitions` | List of service definitions to evaluate | `list(object)` | - |
| `networks` | List of Docker networks to connect to | `list(string)` | `[]` |

## Outputs

| Output | Description |
|--------|-------------|
| `container_name` | The name of the deployed Caddy container |
| `config_hash` | The SHA256 hash of the generated Caddyfile content |
| `service_sites` | Map of generated Caddy site configurations |

## Example Service Integration

### Basic Service with Default Settings

```hcl
# Example based on ntfy (reverse-proxy only with direct IP exposure)
output "service_definition" {
  description = "Service definition for a notification service"
  value = {
    name         = "ntfy"
    primary_port = 80
    endpoint     = "http://ntfy:80"
    subdomains   = ["ntfy"]
  }
}
```

### Service with Custom Caddy Configuration

```hcl
# Example showing a service with custom Caddy configuration
output "service_definition" {
  description = "Service definition with custom Caddy configuration"
  value = {
    name         = "custom-service"
    primary_port = 8080
    endpoint     = "http://custom-service:8080"
    subdomains   = ["custom"]
    caddy_config = <<-EOT
      # Handle API requests specially
      handle /api/* {
        reverse_proxy custom-service:8080 {
          header_up X-Real-IP {remote}
        }
      }
      
      # Handle all other requests
      handle {
        reverse_proxy custom-service:8080
        header +Access-Control-Allow-Origin "*"
      }
    EOT
  }
}
```