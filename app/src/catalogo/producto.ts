export interface Producto {
  id: string;
  nombre: string;
  precio: number;
  stock: number;
}

export interface RepositorioProductos {
  listar(): Producto[];
  buscar(id: string): Producto | undefined;
}
