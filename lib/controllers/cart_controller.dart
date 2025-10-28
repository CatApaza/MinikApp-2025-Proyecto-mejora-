import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product_model.dart';
import '../models/cart_model.dart';

class CartController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  double get totalPrice => _items.fold(
      0.0, (total, item) => total + (item.product.precio * item.quantity));

  CartController() {
    // Cargar carrito al iniciar
    _loadCartFromPrefs();
    // Escuchar cambios de usuario
    _auth.authStateChanges().listen((user) {
      _loadCartFromPrefs();
    });
  }

  /// 🔹 Obtener UID actual
  String? get _userId => _auth.currentUser?.uid;

  /// 🔹 Nombre clave único para cada usuario
  String _prefsKey() => "cart_${_userId ?? 'guest'}";

  /// 🔹 Cargar carrito desde SharedPreferences
  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey());
    _items.clear();

    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      for (var item in decoded) {
        _items.add(CartItem(
          product: Product(
            id: item['productId'],
            nombre: item['nombre'],
            precio: (item['precio'] as num).toDouble(),
            stock: item['stock'] ?? 999,
            imageUrl: item['imageUrl'] ?? "",
            categoria: item['categoria'] ?? "Otros",
          ),
          quantity: item['cantidad'],
        ));
      }
    }
    notifyListeners();
  }

  /// 🔹 Guardar carrito en SharedPreferences
  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _items.map((item) => {
          'productId': item.product.id,
          'nombre': item.product.nombre,
          'precio': item.product.precio,
          'cantidad': item.quantity,
          'stock': item.product.stock,
          'imageUrl': item.product.imageUrl,
          'categoria': item.product.categoria,
        }).toList();
    await prefs.setString(_prefsKey(), jsonEncode(data));
  }

  /// 🔹 Agregar producto al carrito
  void addItem(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      incrementItemQuantity(product);
    } else {
      if (product.stock <= 0) {
        Get.snackbar(
          "Producto agotado",
          "Este producto no está disponible.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade300,
          colorText: Colors.white,
        );
        return;
      }
      _items.add(CartItem(product: product, quantity: 1));
      Get.snackbar(
        "Producto agregado",
        "${product.nombre} fue añadido al carrito ✅",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade300,
        colorText: Colors.white,
      );
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void removeItem(Product product) {
    _items.removeWhere((item) => item.product.id == product.id);
    _saveCartToPrefs();
    notifyListeners();
  }

  void incrementItemQuantity(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      if (_items[index].quantity < product.stock) {
        _items[index].incrementQuantity();
        _saveCartToPrefs();
        notifyListeners();
      } else {
        Get.snackbar(
          "Producto agotado",
          "No hay más stock disponible de ${product.nombre}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade300,
          colorText: Colors.white,
        );
      }
    }
  }

  void decrementItemQuantity(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].decrementQuantity();
      } else {
        removeItem(product);
      }
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  /// 🔹 Limpiar carrito (por ejemplo al cambiar de usuario o al comprar)
  void clearCart() {
    _items.clear();
    _saveCartToPrefs();
    notifyListeners();
  }
}
