import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import 'order_controller.dart';

class PaymentController {
  final CollectionReference pagosCollection =
      FirebaseFirestore.instance.collection('pagos');
  final OrderController _orderController = OrderController();

  // 🔹 Generar referencia aleatoria (no tocar)
  String _generarReferencia() {
    final rnd = Random();
    return 'YP-${DateTime.now().millisecondsSinceEpoch}-${rnd.nextInt(9999)}';
  }

  // 🔹 Crear pago
  Future<String> crearPago({
    required String orderId,
    required String userId,
    required double amount,
    required String method, // "Yape", "BCP"
  }) async {
    final ref = pagosCollection.doc();
    final paymentData = {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'method': method,
      'status': 'pending',
      'reference': _generarReferencia(),
      'timestamp': FieldValue.serverTimestamp(),
    };
    await ref.set(paymentData);
    return ref.id;
  }

  // 🔹 Obtener pagos por usuario
  Stream<List<PaymentModel>> getPaymentsByUser(String userId) {
    return pagosCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data.containsKey('timestamp') && data['timestamp'] != null;
          })
          .map((d) =>
              PaymentModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      return list;
    });
  }

  // 🔹 Actualizar estado de pago
  Future<void> updatePaymentStatus(String paymentId, String status) async {
    final docRef = pagosCollection.doc(paymentId);
    await docRef.update({'status': status});

    if (status == 'completed') {
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>;
      final orderId = data['orderId'] as String?;
      final method = data['method'] as String? ?? 'Yape';
      if (orderId != null && orderId.isNotEmpty) {
        await _orderController.markPedidoComoPagado(orderId, method);
      }
    }
  }

  // 🔹 Simular pago completado (demo)
  Future<void> simularPagoCompletado(String paymentId) async {
    await updatePaymentStatus(paymentId, 'completed');
  }

  // 🔹 Obtener un pago específico por ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final doc = await pagosCollection.doc(paymentId).get();
    if (!doc.exists) return null;
    return PaymentModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // 🟢 Nuevo: Filtrar pagos por fecha (como el de pedidos)
  Stream<List<PaymentModel>> getPaymentsByUserAndDate(
    String userId,
    DateTime fecha,
  ) {
    // Rango de tiempo (00:00 - 23:59)
    final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));

    return pagosCollection
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: inicioDelDia)
        .where('timestamp', isLessThan: finDelDia)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        return PaymentModel.fromMap(d.id, d.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
