# LLDAP Module

This module deploys [](), an app to manage users for authentik, as a container in the homelab environment.

## Overview

The LLDAP Module

- Deploys a container
    - `LLDAP`: The main LLDAP server holding my users.

## Usage:
```hcl
module "lldap" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.lldap_image
  tag            = local.lldap_tag
  volumes        = local.lldap_volumes
  env_vars       = local.lldap_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}
```

## Outputs

| Output               | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `service_definition` | Service definition for integration with networking modules |

## Service Definition

This module outputs a service definition that is used by the networking modules to expose the service.

```hcl
output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.lldap_internal_port
    endpoint     = "http://${local.container_name}:${local.lldap_internal_port}"
    subdomains   = ["users"]
    ports        = []
  }
}```

## Example Integration in Main Configuration

```hcl
module "lldap" {
  source = "${local.module_dir}/30-services-software/lldap-service"
  volume_path = "${local.root_volume}/lldap"
  networks = [
    module.homelab_docker_network.name
  ]
}
```