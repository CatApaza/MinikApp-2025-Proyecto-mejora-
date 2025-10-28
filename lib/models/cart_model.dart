import '../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  void incrementQuantity() {
    quantity++;
  }

  void decrementQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }

  /// Guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      "product": product.toMap(),
      "quantity": quantity,
    };
  }

  /// Leer desde Firestore
  factory CartItem.fromMap(Map<String, dynamic> map) {
    final productData = map["product"];
    if (productData == null || productData is! Map<String, dynamic>) {
      throw Exception("❌ Error: producto inválido en CartItem");
    }

    return CartItem(
      product: Product.fromMap(
        productData,
        productData["id"] ?? "", // Aseguramos que siempre tenga id
      ),
      quantity: (map["quantity"] ?? 1) is int
          ? map["quantity"]
          : int.tryParse(map["quantity"].toString()) ?? 1,
    );
  }
}
