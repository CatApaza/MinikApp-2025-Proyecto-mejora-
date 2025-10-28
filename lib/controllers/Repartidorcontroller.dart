import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';

class RepartidorController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Obtener pedidos asignados a este repartidor
  Stream<List<OrderModel>> obtenerPedidosAsignados(String repartidorId) {
    // 🔹 Si quieres ordenar por fecha, recuerda crear un índice compuesto en Firestore
    return _db
        .collection('pedidos')
        .where('repartidorId', isEqualTo: repartidorId)
        //.orderBy('fecha', descending: true) // ⚠️ Solo si creas índice
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return OrderModel(
                id: doc.id,
                userId: data['userId'] ?? '',
                items: List<Map<String, dynamic>>.from(data['items'] ?? []),
                total: (data['total'] ?? 0).toDouble(),
                metodoEntrega: data['metodoEntrega'] ?? 'Delivery',
                metodoPago: data['metodoPago'] ?? 'Contra entrega',
                estado: data['estado'] ?? 'Pendiente',
                fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
                direccion: data['direccion'] ?? '',
              );
            }).toList());
  }

  // 🔹 Actualizar estado del pedido
  Future<void> actualizarEstadoPedido(String pedidoId, String nuevoEstado) async {
    await _db.collection('pedidos').doc(pedidoId).update({'estado': nuevoEstado});
  }
}
