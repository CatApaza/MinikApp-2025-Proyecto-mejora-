import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String method;
  final String status; // pending | completed | failed
  final String reference;
  final DateTime? timestamp;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    required this.reference,
    this.timestamp,
  });

  factory PaymentModel.fromMap(String id, Map<String, dynamic> data) {
    return PaymentModel(
      id: id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'] ?? '',
      status: data['status'] ?? 'pending',
      reference: data['reference'] ?? '',
      timestamp: data['timestamp'] is Timestamp ? (data['timestamp'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'userId': userId,
    'amount': amount,
    'method': method,
    'status': status,
    'reference': reference,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
  };
}
