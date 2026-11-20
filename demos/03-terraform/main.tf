# Demo: infraestructura local con el provider de Docker.
# No requiere cuenta de nube: cualquiera puede hacer plan/apply en su laptop.
# DEMO: pedirle a la IA que agregue algo (p.ej. una red dedicada o límites de memoria)
#       y validar SIEMPRE con fmt -> validate -> plan antes de apply.

terraform {
  required_version = ">= 1.6"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "catalogo" {
  name = "${var.nombre}-net"
}

resource "docker_image" "catalogo" {
  name = "${var.nombre}:${var.version_app}"

  build {
    context = "${path.module}/../../app"
  }

  triggers = {
    src_hash = sha1(join("", [for f in fileset("${path.module}/../../app/src", "**") : filesha1("${path.module}/../../app/src/${f}")]))
  }
}

resource "docker_container" "catalogo" {
  name     = var.nombre
  image    = docker_image.catalogo.image_id
  restart  = "unless-stopped"
  memory   = var.memoria_mb
  must_run = true

  env = [
    "PORT=3000",
    "APP_VERSION=${var.version_app}",
  ]

  ports {
    internal = 3000
    external = var.puerto_host
  }

  networks_advanced {
    name = docker_network.catalogo.name
  }

  healthcheck {
    test     = ["CMD", "wget", "-qO-", "http://127.0.0.1:3000/health/live"]
    interval = "15s"
    timeout  = "3s"
    retries  = 3
  }
}
