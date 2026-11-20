import { serve } from "@hono/node-server";
import { crearApp } from "./app.js";

const port = Number(process.env.PORT ?? 3000);
const version = process.env.APP_VERSION ?? "dev";

serve({ fetch: crearApp({ version }).fetch, port }, (info) => {
  console.log(JSON.stringify({ level: "info", msg: "catalogo-api escuchando", port: info.port, version }));
});
