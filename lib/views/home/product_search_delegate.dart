import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../models/product_model.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final HomeController homeController;

  ProductSearchDelegate(this.homeController);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = "",
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    homeController.searchProducts(query);
    final results = homeController.filteredProducts;

    if (results.isEmpty) {
      return const Center(child: Text("No se encontraron productos."));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return _buildProductCard(context, product);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    homeController.searchProducts(query);
    final results = homeController.filteredProducts;

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return _buildProductCard(context, product);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showAddToCartDialog(context, product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "S/ ${product.precio.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Stock: ${product.stock}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_shopping_cart,
                color: Colors.green.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddToCartDialog(BuildContext context, Product product) {
    final cartController = Provider.of<CartController>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(product.imageUrl, height: 150, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(
                product.nombre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "S/ ${product.precio.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, color: Colors.green.shade700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                "Stock disponible: ${product.stock}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text("¿Quieres añadir este producto al carrito?", textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      cartController.addItem(product);
                      Navigator.pop(context);
                      close(context, product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${product.nombre} añadido al carrito")),
                      );
                    },
                    child: const Text("Añadir"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
