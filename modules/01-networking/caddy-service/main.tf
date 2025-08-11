terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  container_name = var.container_name != "" ? var.container_name : "caddy"
  image_tag      = var.image_tag != "" ? var.image_tag : "latest"

  // Filter services to only include those that should be published via reverse proxy
  proxy_services = [
    for service in var.service_definitions :
    service if length(service.subdomains) > 0
  ]

  // Transform service definitions into Caddyfile blocks
  caddy_site_configs = flatten([
    for service in local.proxy_services :
    [
      for domain in var.domains : [
        for subdomain in service.subdomains : {
          site_address          = "${subdomain}.${domain}"
          endpoint              = service.endpoint
          service_name          = service.name
          has_custom_config     = service.caddy_config != ""
          custom_config         = service.caddy_config
          reverse_proxy_options = service.caddy_options
        }
      ]
    ]
  ])

  caddyfile_default = <<-EOT
  {
    email ${var.tls_email}

    log {
      format console
      output stdout
    }
  }

  (headers) {
    header {
      -server
      -via
      
      Permissions-Policy interest-cohort=()

      Strict-Transport-Security "max-age=31536000; includesSubDomains; preload"

      X-Content-Type-Options "nosniff"

      X-Frame-Options DENY
    }
  }

  EOT

  // Generate the main Caddyfile content
  caddyfile_content = format("%s%s", local.caddyfile_default, join("\n\n", [
    for site in local.caddy_site_configs :
    site.has_custom_config ?
    // Use the custom Caddy config if provided
    <<-EOT
    ${site.site_address} {
      import headers
      ${site.custom_config}
    }
    EOT
    :
    // Otherwise use the standard reverse proxy config with options
    <<-EOT
    ${site.site_address} {
      import headers
      reverse_proxy ${site.endpoint} {
        ${join("\n        ", [
    for key, value in site.reverse_proxy_options :
    "${key} ${value}"
])}
      }
    }
    EOT
]))
}

resource "docker_volume" "caddy_config" {
  name = "${local.container_name}_config"
}

// Create Caddyfile in the volume path
resource "local_file" "caddyfile" {
  content  = local.caddyfile_content
  filename = "${var.volume_path}/${local.container_name}/Caddyfile"
}


module "caddy" {
  source = "../../10-generic/docker-service"

  container_name = local.container_name
  image          = "caddy"
  tag            = local.image_tag

  volumes = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/data"
      container_path = "/data"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/config"
      container_path = "/config"
      read_only      = false
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/Caddyfile"
      container_path = "/etc/caddy/Caddyfile"
      read_only      = true
    }
  ]

  ports = [
    {
      external = "80"
      internal = "80"
      protocol = "tcp"
    },
    {
      external = "443"
      internal = "443"
      protocol = "tcp"
    }
  ]

  networks   = var.networks
}