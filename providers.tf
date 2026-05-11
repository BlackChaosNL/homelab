terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }

    dotenv = {
      source  = "germanbrew/dotenv"
      version = "1.2.10"
    }
  }
}

provider "docker" {
  host = provider::dotenv::get_by_key("DOCKER_SOCK", "${path.module}/.env")
}
