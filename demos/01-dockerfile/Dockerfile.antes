# Versión "antes": así llega un Dockerfile típico a revisión.
# DEMO: pídele a la IA que lo revise y lo mejore (ver prompts/01-dockerfile.md).
# Problemas sembrados a propósito:
#  - imagen base sin versión fija (latest) y pesada
#  - un solo stage: dependencias de desarrollo en la imagen final
#  - COPY . . antes de instalar -> rompe la caché de capas
#  - npm install en lugar de npm ci (no reproducible)
#  - secreto horneado en la imagen
#  - corre como root, sin HEALTHCHECK
FROM node:latest

WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

ENV API_KEY=sk-live-1234567890abcdef
EXPOSE 3000
CMD npm start
