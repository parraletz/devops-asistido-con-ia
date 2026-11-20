output "url" {
  description = "URL local de la API"
  value       = "http://localhost:${var.puerto_host}/productos"
}

output "contenedor" {
  description = "Nombre del contenedor"
  value       = docker_container.catalogo.name
}
