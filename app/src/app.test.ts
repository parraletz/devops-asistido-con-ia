import { describe, expect, it } from "vitest";
import { crearApp } from "./app.js";

describe("catalogo-api", () => {
  const app = crearApp({ version: "test" });

  it("responde liveness", async () => {
    const res = await app.request("/health/live");
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: "ok" });
  });

  it("expone la versión en readiness", async () => {
    const res = await app.request("/health/ready");
    expect((await res.json()).version).toBe("test");
  });

  it("lista productos", async () => {
    const res = await app.request("/productos");
    expect(res.status).toBe(200);
    expect((await res.json()).length).toBeGreaterThan(0);
  });

  it("devuelve 404 para un producto inexistente", async () => {
    const res = await app.request("/productos/no-existe");
    expect(res.status).toBe(404);
  });
});
