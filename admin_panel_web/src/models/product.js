export default class Product {
  constructor(id, nombre, precio, stock, imageUrl, categoria) {
    this.id = id;
    this.nombre = nombre;
    this.precio = precio;
    this.stock = stock;
    this.imageUrl = imageUrl;
    this.categoria = categoria; // 👈 nuevo campo
  }

  static fromFirestore(doc) {
    const data = doc.data();
    return new Product(
      doc.id,
      data.nombre || "",
      data.precio || 0,
      data.stock || 0,
      data.imageUrl || "",
      data.categoria || ""  // 👈 leer categoría de Firestore
    );
  }

  toFirestore() {
    return {
      nombre: this.nombre,
      precio: this.precio,
      stock: this.stock,
      imageUrl: this.imageUrl,
      categoria: this.categoria,  // 👈 guardar categoría
    };
  }
}
