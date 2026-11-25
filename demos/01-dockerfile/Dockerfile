# Versión corregida de Dockerfile.antes (hadolint sin avisos).
# Contexto de build: app/  ->  docker build -f demos/01-dockerfile/Dockerfile -t catalogo-api:demo app

# --- build: aquí viven las dependencias de desarrollo (tsc, vitest...) ---
# DL3007: versión fija y variante alpine (ligera) en lugar de node:latest.
FROM node:22.12-alpine3.21 AS build
WORKDIR /app
# Primero los manifiestos: la capa de dependencias se reutiliza si solo cambia el código.
COPY package.json package-lock.json ./
# npm ci: instalación reproducible a partir del lockfile.
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
# DL3059: build y poda de devDependencies en un solo RUN.
RUN npm run build && npm prune --omit=dev

# --- runtime: solo dependencias de producción y el código compilado ---
FROM node:22.12-alpine3.21
# DL3064: sin secretos en ENV/ARG; API_KEY se inyecta en runtime (docker run -e / secret de K8s).
ENV NODE_ENV=production PORT=3000
WORKDIR /app
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./
# Usuario sin privilegios que ya trae la imagen oficial de node.
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health/live || exit 1
# DL3025: formato JSON; node como PID 1 recibe SIGTERM directamente (sin npm de por medio).
CMD ["node", "dist/server.js"]
