terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  container_name = "anubis"
  image          = "ghcr.io/techarohq/anubis"
  tag            = var.image_tag

  bot_policies = <<-EOT
  bots:
    - name: unblock-subdomains
      headers_regex:
        Host: ^(tandoor|maps)\.blackchaosnl\.myaddr\.dev$
      action: ALLOW
    # You can import the entire default config with this macro:
    - import: (data)/meta/default-config.yaml
  EOT
}

resource "local_file" "bot_policies_file" {
  content  = local.bot_policies
  filename = "${var.volume_path}/${local.container_name}/bot_policies.yaml"
}

module "anubis" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.image
  tag            = local.tag
  env_vars       = {
    BIND        = ":3000"
    TARGET      = "http://10.100.0.1:8080"
    POLICY_FILE = "/etc/anubis/botPolicies.yaml"
  }
  volumes        = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/bot_policies.yaml"
      container_path = "/etc/anubis/botPolicies.yaml"
      read_only      = true
    },
  ]
  ports = [
    {
      internal = 3000
      external = 3333
      protocol = "tcp"
    }
  ]
  restart_policy = "always"
}
