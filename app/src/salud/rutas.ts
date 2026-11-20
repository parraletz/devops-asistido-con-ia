import { Hono } from "hono";

export function rutasSalud(version: string) {
  const app = new Hono();
  const inicio = Date.now();

  // Liveness: el proceso responde
  app.get("/live", (c) => c.json({ status: "ok" }));

  // Readiness: listo para recibir tráfico
  app.get("/ready", (c) =>
    c.json({ status: "ok", version, uptimeSeg: Math.round((Date.now() - inicio) / 1000) }),
  );

  return app;
}
