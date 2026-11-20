import { Hono } from "hono";
import type { RepositorioProductos } from "./producto.js";

export function rutasCatalogo(repo: RepositorioProductos) {
  const app = new Hono();

  app.get("/", (c) => c.json(repo.listar()));

  app.get("/:id", (c) => {
    const producto = repo.buscar(c.req.param("id"));
    if (!producto) return c.json({ error: "producto no encontrado" }, 404);
    return c.json(producto);
  });

  return app;
}
