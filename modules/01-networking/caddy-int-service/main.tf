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
          is_route_protected    = service.is_guarded
          has_custom_config     = service.caddy_config != ""
          custom_config         = service.caddy_config
          reverse_proxy_options = service.caddy_options
        }
      ]
    ]
  ])

  caddyfile_default = <<-EOT
  # !!!DO NOT EDIT!!!
  # Automatically generated through OpenTofu, changes will not be persisted upon reapplication.
  {
    auto_https off

    servers {
        trusted_proxies static 172.16.0.0/12 10.0.0.0/8 192.168.0.0/16 10.88.0.0/16 10.100.0.0/24
    }
  }

  :80 {
    import caddy/*.caddyfile
  }
  EOT

  // Generate the main Caddyfile content
  generate_caddyfile_content = join("\n\n", [
    for site in local.caddy_site_configs :
    // Use the custom Caddy config if provided
    <<-EOT
    # !!!DO NOT EDIT!!!
    # Automatically generated through OpenTofu, changes will not be persisted upon reapplication.
    @${site.service_name} host ${site.site_address}
    handle @${site.service_name} {
      route {
        %{if site.has_custom_config}
        ${site.custom_config}
        %{else}
        reverse_proxy ${site.endpoint} {
          ${join("\n        ", [for key, value in site.reverse_proxy_options : "${key} ${value}"])}
        }
        %{endif}
      }
    }
    EOT
  ])
}

resource "docker_volume" "caddy_config" {
  name = "${local.container_name}_config"
}

// Create Caddyfile in the volume path
resource "local_file" "caddyfile" {
  content  = local.caddyfile_default
  filename = "${var.volume_path}/${local.container_name}/Caddyfile"
}

resource "local_file" "generated_caddyfile" {
  content  = local.generate_caddyfile_content
  filename = "${var.volume_path}/${local.container_name}/caddy/generated.caddyfile"
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
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/caddy"
      container_path = "/etc/caddy/caddy"
      read_only      = true
    }
  ]

  ports = [
    {
      external = "8080"
      internal = "80"
      protocol = "tcp"
    }
  ]

  networks = var.networks
}
