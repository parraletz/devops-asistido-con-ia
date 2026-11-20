# Versión "después": revisada con IA + validada con hadolint
# Multi-arquitectura (linux/amd64 + linux/arm64):
#   docker buildx build --platform linux/amd64,linux/arm64 -t <imagen> app
# El stage de build corre en la arquitectura NATIVA del builder ($BUILDPLATFORM):
# compilar TypeScript y las dependencias (JS puro) no dependen de la CPU, así que
# no hace falta emulación QEMU. El stage final no tiene RUN: solo copia archivos.
# --- build ---
FROM --platform=$BUILDPLATFORM node:22.12-alpine3.21 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build && npm prune --omit=dev

# --- runtime ---
FROM node:22.12-alpine3.21
ENV NODE_ENV=production PORT=3000
WORKDIR /app
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health/live || exit 1
CMD ["node", "dist/server.js"]
