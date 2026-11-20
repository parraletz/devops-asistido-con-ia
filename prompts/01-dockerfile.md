# Demo 1 · Revisar y mejorar un Dockerfile

**Archivo:** `demos/01-dockerfile/Dockerfile.antes` → resultado esperado parecido a `app/Dockerfile`

## Prompt 1: revisión (primero diagnosticar, no reescribir)
```
Actúa como ingeniero DevOps senior. Revisa demos/01-dockerfile/Dockerfile.antes
para una API Node.js + TypeScript (código en app/). NO lo reescribas todavía.
Dame una tabla con: problema, severidad (alta/media/baja), por qué importa y cómo arreglarlo.
Considera seguridad, tamaño de imagen, caché de capas y reproducibilidad.
```

## Prompt 2: corrección con restricciones explícitas
```
Ahora genera el Dockerfile corregido con estas restricciones:
- multi-stage, imagen base node 22 alpine con versión fija
- npm ci, sin dependencias de desarrollo en la imagen final
- usuario no root, HEALTHCHECK contra /health/live
- ningún secreto en la imagen: los secretos llegan por variables de entorno en runtime
Explica cada decisión en un comentario de una línea.
```

## Validación humana (en vivo)
```bash
docker run --rm -i hadolint/hadolint < app/Dockerfile
docker build -t catalogo-api:demo app
docker run --rm -p 3000:3000 catalogo-api:demo
curl localhost:3000/health/live
docker image ls catalogo-api      # comparar tamaño vs. la versión "antes"
```

**Punto a remarcar:** la IA detecta el secreto horneado, pero *rotar ese secreto* es trabajo humano: ya quedó en la historia de la imagen.
