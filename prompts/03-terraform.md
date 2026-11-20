# Demo 3 · Infraestructura como código con IA

**Carpeta:** `demos/03-terraform` (provider Docker: corre en cualquier laptop, sin nube)

## Prompt 1: entender antes de cambiar
```
Explícame qué crea demos/03-terraform/main.tf, en qué orden y qué pasaría
si cambio var.nombre después de aplicar. Sé breve.
```

## Prompt 2: cambio acotado
```
Agrega a demos/03-terraform:
- una variable "replicas" (1 a 3, con validation) que cree N contenedores con count,
  cada uno en un puerto host consecutivo a partir de var.puerto_host
- un output con la lista de URLs
No cambies el nombre de los recursos existentes. Muéstrame el diff antes de escribir.
```

## Validación humana: el flujo que NO se negocia
```bash
cd demos/03-terraform
terraform fmt -check
terraform init
terraform validate
terraform plan -out=tfplan          # LEER el plan: ¿hay "destroy" o "forces replacement"?
terraform apply tfplan
curl "$(terraform output -raw url)"
terraform destroy
```

**Puntos a remarcar:**
- Agregar `count` a un recurso existente cambia su dirección (`docker_container.catalogo` → `docker_container.catalogo[0]`): el plan mostrará destroy/create. Esto es exactamente lo que la IA puede no avisar; el `plan` sí. Solución: bloque `moved {}`.
- Usa el MCP de Terraform Registry para que la IA consulte la versión real del provider en vez de inventarla.
