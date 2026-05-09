terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  container_name = var.container_name
  image_tag      = var.image_tag

  proxy_services = [
    for service in var.service_definitions :
    service if length(service.subdomains) > 0
  ]

  caddy_site_configs = flatten([
    for service in local.proxy_services :
    [
      for domain in var.domains : [
        for subdomain in service.subdomains : "${subdomain}.${domain}"
      ]
    ]
  ])

  caddyfile_default = <<-EOT
  # !!!DO NOT EDIT!!!
  # Automatically generated through OpenTofu, changes will not be persisted upon reapplication.
  {
    tls ${var.tls_email}
  }

  ${join(", ", flatten(var.domains))} ${join(", ", flatten(local.caddy_site_configs))} { 
      reverse_proxy http://anubis:3000 {
        header_up X-Real-Ip {remote_host}
        header_up X-Http-Version {http.request.proto}
      }
  }
  EOT
}

resource "docker_volume" "caddy_config" {
  name = "${local.container_name}_config"
}

// Create Caddyfile in the volume path
resource "local_file" "caddyfile" {
  content  = local.caddyfile_default
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
    },
    {
      host_path      = "${var.volume_path}/${local.container_name}/caddy"
      container_path = "/etc/caddy/caddy"
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
}