import type { Producto, RepositorioProductos } from "./producto.js";

const PRODUCTOS_INICIALES: Producto[] = [
  { id: "p-001", nombre: "Taza DevOps", precio: 12.5, stock: 40 },
  { id: "p-002", nombre: "Playera Kubernetes", precio: 22, stock: 15 },
  { id: "p-003", nombre: "Sticker Terraform", precio: 2, stock: 300 },
];

export function crearRepositorioEnMemoria(
  productos: Producto[] = PRODUCTOS_INICIALES,
): RepositorioProductos {
  const porId = new Map(productos.map((p) => [p.id, p]));
  return {
    listar: () => [...porId.values()],
    buscar: (id) => porId.get(id),
  };
}
