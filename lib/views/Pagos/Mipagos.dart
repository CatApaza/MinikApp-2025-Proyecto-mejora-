import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/payment_controller.dart';
import '../../services/pdf_service.dart';
import '../../models/payment_model.dart';
import '../../models/order_model.dart';

class MisPagos extends StatefulWidget {
  const MisPagos({super.key});

  @override
  State<MisPagos> createState() => _MisPagosState();
}

class _MisPagosState extends State<MisPagos> {
  final PaymentController _paymentController = PaymentController();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  DateTime? _selectedDate; // 🔹 Nueva variable para filtro por fecha

  String _traducirEstado(String status) {
    switch (status) {
      case 'completed':
        return 'Pago Realizado';
      case 'pending':
        return 'Pendiente de Pago';
      case 'failed':
        return 'Pago Fallido';
      default:
        return 'Desconocido';
    }
  }

  Color _colorEstado(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // 🔹 Selector de fecha (DatePicker)
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _selectedDate == null
        ? _paymentController.getPaymentsByUser(userId)
        : _paymentController.getPaymentsByUserAndDate(userId, _selectedDate!);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Pagos"),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _seleccionarFecha,
            tooltip: "Filtrar por fecha",
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() => _selectedDate = null);
              },
              tooltip: "Limpiar filtro",
            ),
        ],
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pagos = snapshot.data ?? [];

          if (pagos.isEmpty) {
            return Center(
              child: Text(
                _selectedDate == null
                    ? "Aún no tienes pagos registrados."
                    : "No hay pagos en la fecha seleccionada.",
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pagos.length,
            itemBuilder: (context, index) {
              final pago = pagos[index];
              final fecha = pago.timestamp != null
                  ? "${pago.timestamp!.day}/${pago.timestamp!.month}/${pago.timestamp!.year}"
                  : "Sin fecha";

              final estadoTraducido = _traducirEstado(pago.status);
              final colorEstado = _colorEstado(pago.status);

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    "Monto: S/ ${pago.amount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Método: ${pago.method}"),
                      Text("Referencia: ${pago.reference}"),
                      Text("Fecha: $fecha"),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(
                          estadoTraducido,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: colorEstado,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.picture_as_pdf,
                      color: pago.status == 'completed'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    onPressed: pago.status == 'completed'
                        ? () async {
                            final orderDoc = await FirebaseFirestore.instance
                                .collection('pedidos')
                                .doc(pago.orderId)
                                .get();

                            if (!orderDoc.exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "No se encontró el pedido asociado."),
                                ),
                              );
                              return;
                            }

                            final orderMap =
                                orderDoc.data() as Map<String, dynamic>;
                            final order =
                                OrderModel.fromMap(orderMap, pago.orderId);

                            final bytes =
                                await PdfService.generateOrderInvoice(order);
                            await PdfService.printBytes(
                              bytes,
                              filename: 'Boleta_${order.id}.pdf',
                            );
                          }
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
