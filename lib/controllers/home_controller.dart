import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../controllers/product_controller.dart';
import '../../models/user_models.dart';

class HomeController extends ChangeNotifier {
  final UserModel user;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isDarkMode = false; // 🌙 Nuevo

  List<Product> get filteredProducts => _filteredProducts;
  bool get isDarkMode => _isDarkMode; // 🌙 Nuevo getter

  HomeController({required this.user}) {
    loadProducts();
  }

  void loadProducts() {
    getProducts().listen((products) {
      _allProducts = products;
      _filteredProducts = _allProducts;
      notifyListeners();
    });
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((p) =>
              p.nombre.toLowerCase().contains(query.toLowerCase()) ||
              p.precio.toString().contains(query))
          .toList();
    }
    notifyListeners();
  }

  void filterByCategory(String category) {
    if (category == "Todos") {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts =
          _allProducts.where((p) => p.categoria == category).toList();
    }
    notifyListeners();
  }

  // 🌗 Nuevo: alternar modo oscuro / claro
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
