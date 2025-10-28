class Product {
  final String id;
  final String nombre;
  final double precio;
  final int stock;
  final String imageUrl;
  final String categoria;

  Product({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.imageUrl,
    required this.categoria,
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    int stockValue = 0;

    if (data['stock'] is int) {
      stockValue = data['stock'];
    } else if (data['stock'] is double) {
      stockValue = (data['stock'] as double).toInt();
    } else if (data['stock'] is String) {
      stockValue = int.tryParse(data['stock']) ?? 0;
    }

    return Product(
      id: id,
      nombre: data['nombre'] ?? '',
      precio: (data['precio'] ?? 0).toDouble(),
      stock: stockValue,
      imageUrl: data['imageUrl'] ?? '',
      categoria: data['categoria'] ?? 'Otros',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'imageUrl': imageUrl,
      'categoria': categoria,
    };
  }
}
