import { Hono } from "hono";
import { logger } from "hono/logger";
import { crearRepositorioEnMemoria } from "./catalogo/repositorio-en-memoria.js";
import { rutasCatalogo } from "./catalogo/rutas.js";
import type { RepositorioProductos } from "./catalogo/producto.js";
import { rutasSalud } from "./salud/rutas.js";

export function crearApp(opts: { version?: string; repo?: RepositorioProductos } = {}) {
  const app = new Hono();
  app.use("*", logger());
  app.route("/health", rutasSalud(opts.version ?? "dev"));
  app.route("/productos", rutasCatalogo(opts.repo ?? crearRepositorioEnMemoria()));
  return app;
}
