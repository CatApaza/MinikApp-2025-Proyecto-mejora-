import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderController {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection("pedidos");
  final CollectionReference productsCollection =
      FirebaseFirestore.instance.collection("productos");

  /// Crear pedido y devolver ID real en lugar de solo true/false
  Future<String?> crearPedido(OrderModel order) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final batch = FirebaseFirestore.instance.batch();

      // Verificar stock y actualizar productos
      for (var item in order.items) {
        final docRef = productsCollection.doc(item['productId']);
        final snapshot = await docRef.get();
        final data = snapshot.data() as Map<String, dynamic>;

        int stockActual = data['stock'] ?? 0;
        if (stockActual < item['cantidad']) {
          if (kDebugMode) print("❌ Producto ${item['nombre']} agotado");
          return null; // fallo
        }
        batch.update(docRef, {'stock': stockActual - item['cantidad']});
      }

      // Crear nuevo pedido
      final newOrderRef = ordersCollection.doc();

      // 🔹 Generar displayId legible
      final displayId =
          "Pedido-${DateTime.now().millisecondsSinceEpoch % 100000}";

      batch.set(newOrderRef, {
        ...order.toMap(),
        "userId": user.uid,
        "nombreCliente": user.displayName ?? "Sin nombre",
        "correoCliente": user.email ?? "Sin correo",
        "estado": "Pendiente",
        "displayId": displayId,
        "fechaCreacion": FieldValue.serverTimestamp(),
      });

      await batch.commit();
      if (kDebugMode) print("✅ Pedido creado correctamente: ${newOrderRef.id}");
      return newOrderRef.id; // devolvemos ID real
    } catch (e) {
      if (kDebugMode) print("❌ Error al crear pedido: $e");
      return null;
    }
  }

  Stream<List<OrderModel>> getPedidosByUser(String userId) {
    return ordersCollection
        .where("userId", isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> markPedidoComoPagado(String orderId, String metodo) async {
    try {
      await ordersCollection.doc(orderId).update({
        "estado": "Pagado",
        "metodoPago": metodo,
        "fechaPago": FieldValue.serverTimestamp(),
      });
      if (kDebugMode) print("✅ Pedido $orderId marcado como pagado con $metodo");
    } catch (e) {
      if (kDebugMode) print("❌ Error al marcar pedido como pagado: $e");
      rethrow;
    }
  }

  // 🆕 NUEVA FUNCIÓN: filtrar pedidos por texto o fecha
  Stream<List<OrderModel>> getPedidosByUserFiltered(
    String userId, {
    String? search,
    DateTime? fechaFiltro,
  }) {
    return ordersCollection
        .where("userId", isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      var pedidos = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // 🔹 Filtrar por búsqueda
      if (search != null && search.trim().isNotEmpty) {
        final query = search.toLowerCase();
        pedidos = pedidos.where((p) {
          return p.estado.toLowerCase().contains(query) ||
              p.id.toLowerCase().contains(query) ||
              p.items.any((item) =>
                  item['nombre'].toString().toLowerCase().contains(query));
        }).toList();
      }

      // 🔹 Filtrar por fecha
      if (fechaFiltro != null) {
        pedidos = pedidos.where((p) {
          return p.fecha.year == fechaFiltro.year &&
              p.fecha.month == fechaFiltro.month &&
              p.fecha.day == fechaFiltro.day;
        }).toList();
      }

      return pedidos;
    });
  }
}
