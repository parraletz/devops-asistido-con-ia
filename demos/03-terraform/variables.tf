variable "nombre" {
  description = "Nombre base de los recursos"
  type        = string
  default     = "catalogo-api"
}

variable "version_app" {
  description = "Versión de la aplicación (tag de la imagen)"
  type        = string
  default     = "1.0.0"
}

variable "puerto_host" {
  description = "Puerto expuesto en el host"
  type        = number
  default     = 8080

  validation {
    condition     = var.puerto_host > 1024 && var.puerto_host < 65536
    error_message = "Usa un puerto no privilegiado (1025-65535)."
  }
}

variable "memoria_mb" {
  description = "Límite de memoria del contenedor en MB"
  type        = number
  default     = 256
}
