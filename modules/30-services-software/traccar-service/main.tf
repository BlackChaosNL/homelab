terraform {
  required_providers {
    dotenv = {
      source = "germanbrew/dotenv"
    }
  }
}

locals {
  container_name         = "traccar"
  traccar_image          = "docker.io/traccar/traccar"
  traccar_tag            = var.image_tag
  traccar_internal_port  = 8082

  traccar_env_vars = {
    PUID        = var.user_id
    PGID        = var.group_id
    TZ          = var.timezone
  }

  traccar_content = <<-EOT
  <?xml version='1.0' encoding='UTF-8'?>
  <!DOCTYPE properties SYSTEM 'http://java.sun.com/dtd/properties.dtd'>
  <properties>
    <!-- Documentation: https://www.traccar.org/configuration-file/ -->

    <entry key='database.driver'>org.h2.Driver</entry>
    <entry key='database.url'>jdbc:h2:./data/database</entry>
    <entry key='database.user'>sa</entry>
    <entry key='database.password'></entry>
  </properties>
  EOT
}

resource "local_file" "traccar_config_file" {
  content  = local.traccar_content
  filename = "${var.volume_path}/${local.container_name}/traccar.xml"
}

module "traccar" {
  source         = "../../10-generic/docker-service"
  container_name = local.container_name
  image          = local.traccar_image
  tag            = local.traccar_tag
  volumes        = [
    {
      host_path      = "${var.volume_path}/${local.container_name}/logs"
      container_path = "/opt/traccar/logs"
      read_only      = false
    },{
      host_path      = "${var.volume_path}/${local.container_name}/data"
      container_path = "/opt/traccar/data"
      read_only      = false
    },{
      host_path      = "${var.volume_path}/${local.container_name}/traccar.xml"
      container_path = "/opt/traccar/conf/traccar.xml"
      read_only      = true
    },
  ]
  env_vars       = local.traccar_env_vars
  networks       = concat(var.networks)
  restart_policy = "always"
}

output "service_definition" {
  description = "General service definition with optional ingress configuration"
  value = {
    name         = local.container_name
    primary_port = local.traccar_internal_port
    endpoint     = "http://${local.container_name}:${local.traccar_internal_port}"
    subdomains   = ["maps"]
    is_guarded   = true
  }
}