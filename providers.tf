terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }

    dotenv = {
      source  = "germanbrew/dotenv"
      version = "1.2.5"
    }
  }
}

provider "docker" {
  host = provider::dotenv::get_by_key("DOCKER_SOCK", "${path.module}/.env")
}
