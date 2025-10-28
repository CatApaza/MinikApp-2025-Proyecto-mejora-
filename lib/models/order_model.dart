import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String metodoEntrega;
  final String metodoPago;
  final String estado;
  final DateTime fecha;
  final String? direccion; // Dirección opcional

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.metodoEntrega,
    required this.metodoPago,
    required this.estado,
    required this.fecha,
    this.direccion,
  });

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "items": items,
      "total": total,
      "metodoEntrega": metodoEntrega,
      "metodoPago": metodoPago,
      "estado": estado,
      "fecha": Timestamp.fromDate(fecha),
      "direccion": direccion ?? "",
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      userId: map["userId"] ?? "",
      items: List<Map<String, dynamic>>.from(map["items"] ?? []),
      total: (map["total"] ?? 0).toDouble(),
      metodoEntrega: map["metodoEntrega"] ?? "Delivery",
      metodoPago: map["metodoPago"] ?? "Contra entrega",
      estado: map["estado"] ?? "Pendiente",
      fecha: (map["fecha"] is Timestamp)
          ? (map["fecha"] as Timestamp).toDate()
          : DateTime.now(),
      direccion: map["direccion"] ?? "",
    );
  }
}
