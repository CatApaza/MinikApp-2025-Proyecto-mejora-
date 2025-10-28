import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/order_model.dart';
import '../Pagos/pagos.dart';

class MisPedidosView extends StatefulWidget {
  const MisPedidosView({super.key});

  @override
  State<MisPedidosView> createState() => _MisPedidosViewState();
}

class _MisPedidosViewState extends State<MisPedidosView> {
  final OrderController orderController = OrderController();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _fechaFiltro;

  // 🔹 URL pública de ngrok
  static const ngrokUrl = "https://somnambulistic-twitchingly-becki.ngrok-free.dev";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Pedidos"),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filtrar por fecha',
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _fechaFiltro ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _fechaFiltro = picked);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Quitar filtros',
            onPressed: () {
              setState(() {
                _fechaFiltro = null;
                _searchController.clear();
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar pedido o estado...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: orderController.getPedidosByUserFiltered(
          userId,
          search: _searchController.text,
          fechaFiltro: _fechaFiltro,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No tienes pedidos con esos filtros."));
          }

          final pedidos = snapshot.data!..sort((a, b) => b.fecha.compareTo(a.fecha));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final displayId = "Pedido-${pedido.id.substring(0, 6)}";
              final fechaStr =
                  "${pedido.fecha.day.toString().padLeft(2, '0')}/"
                  "${pedido.fecha.month.toString().padLeft(2, '0')}/"
                  "${pedido.fecha.year}";

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ExpansionTile(
                  title: Text(
                    "$displayId • $fechaStr",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${pedido.items.length} productos • Total: S/ ${pedido.total.toStringAsFixed(2)}\nEstado: ${pedido.estado}",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pedido.items.length,
                      itemBuilder: (context, i) {
                        final item = pedido.items[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.shopping_bag_outlined),
                          title: Text(item['nombre']),
                          subtitle: Text(
                            "Cantidad: ${item['cantidad']} • S/ ${(item['precio'] * item['cantidad']).toStringAsFixed(2)}",
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Método: ${pedido.metodoEntrega} • Dirección: ${pedido.direccion ?? '-'} • Pago: ${pedido.metodoPago}",
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          if ((pedido.metodoPago == "Yape" ||
                                  pedido.metodoPago == "BCP" ||
                                  pedido.metodoPago == "MercadoPago") &&
                              pedido.estado == "Pendiente")
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                              ),
                              onPressed: () async {
                                try {
                                  // 🔹 Mercado Pago
                                  if (pedido.metodoPago == "MercadoPago") {
                                    final response = await http.post(
                                      Uri.parse('$ngrokUrl/create_preference'),
                                      headers: {"Content-Type": "application/json"},
                                      body: jsonEncode({
                                        "title": "Pedido ${pedido.id}",
                                        "price": pedido.total.toDouble(),
                                        "quantity": 1,
                                        "orderId": pedido.id,
                                        "paymentId": pedido.id,
                                        "baseUrl": ngrokUrl,
                                      }),
                                    );

                                    final data = jsonDecode(response.body);
                                    final initPoint = data['sandbox_init_point'];

                                    if (initPoint != null &&
                                        initPoint.isNotEmpty &&
                                        await canLaunchUrl(Uri.parse(initPoint))) {
                                      await launchUrl(Uri.parse(initPoint),
                                          mode: LaunchMode.externalApplication);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("❌ No se pudo abrir la URL de Mercado Pago"),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  // 🔹 Yape / BCP
                                  final paymentController = PaymentController();
                                  final existingPayments = await FirebaseFirestore.instance
                                      .collection('pagos')
                                      .where('orderId', isEqualTo: pedido.id)
                                      .where('status', isEqualTo: 'pending')
                                      .limit(1)
                                      .get();

                                  String paymentId;

                                  if (existingPayments.docs.isNotEmpty) {
                                    paymentId = existingPayments.docs.first.id;
                                  } else {
                                    paymentId = await paymentController.crearPago(
                                      orderId: pedido.id,
                                      userId: userId,
                                      amount: pedido.total,
                                      method: pedido.metodoPago,
                                    );
                                  }

                                  await Future.delayed(const Duration(milliseconds: 300));

                                  final pagoDoc = await FirebaseFirestore.instance
                                      .collection('pagos')
                                      .doc(paymentId)
                                      .get();

                                  if (!pagoDoc.exists) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("❌ Error: no se encontró el documento de pago en Firestore."),
                                      ),
                                    );
                                    return;
                                  }

                                  Get.to(() => Pagosview(
                                        orderId: pedido.id,
                                        paymentId: paymentId,
                                      ));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al procesar el pago: $e'),
                                    ),
                                  );
                                }
                              },
                              child: Text("Pagar con ${pedido.metodoPago}"),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
