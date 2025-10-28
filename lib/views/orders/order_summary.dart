// ... (importaciones igual que antes)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/order_model.dart';
import '../orders/MisPedidos.dart';
import '../Pagos/pagos.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OrderSummary extends StatefulWidget {
  const OrderSummary({super.key});

  @override
  State<OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<OrderSummary> {
  final CartController cartController = Get.find();
  final OrderController orderController = OrderController();
  final PaymentController paymentController = PaymentController();

  String metodoEntrega = "Delivery";
  String direccion = "";
  String metodoPago = "Contra entrega";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resumen de Pedido"),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Productos:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  itemCount: cartController.items.length,
                  itemBuilder: (context, index) {
                    final item = cartController.items[index];
                    return ListTile(
                      leading: Image.network(item.product.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(item.product.nombre),
                      subtitle: Text("Cantidad: ${item.quantity}"),
                      trailing: Text("S/. ${(item.product.precio * item.quantity).toStringAsFixed(2)}"),
                    );
                  },
                );
              }),
            ),
            const Divider(),
            Obx(() => Text(
                  "Total: S/. ${cartController.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )),
            const SizedBox(height: 20),
            const Text("Método de Entrega:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: metodoEntrega,
              items: ["Delivery", "Recojo en tienda"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => metodoEntrega = value);
              },
            ),
            const SizedBox(height: 10),
            if (metodoEntrega == "Delivery")
              TextField(
                decoration: const InputDecoration(labelText: "Dirección de entrega", border: OutlineInputBorder()),
                onChanged: (value) => direccion = value,
              ),
            const SizedBox(height: 20),
            const Text("Método de Pago:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: metodoPago,
              items: ["Contra entrega", "Yape", "BCP", "MercadoPago"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => metodoPago = value);
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () async {
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  final totalFinal = cartController.totalPrice;

                  final itemsMap = cartController.items.map((item) {
                    return {
                      "productId": item.product.id,
                      "nombre": item.product.nombre,
                      "precio": item.product.precio,
                      "cantidad": item.quantity,
                    };
                  }).toList();

                  final order = OrderModel(
                    id: "",
                    userId: userId,
                    items: itemsMap,
                    total: totalFinal,
                    metodoEntrega: metodoEntrega,
                    metodoPago: metodoPago,
                    estado: "Pendiente",
                    fecha: DateTime.now(),
                    direccion: metodoEntrega == "Delivery" ? direccion : null,
                  );

                  final orderId = await orderController.crearPedido(order);
                  if (orderId == null) {
                    Get.snackbar(
                      "Error",
                      "No se pudo crear el pedido ❌",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade300,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  cartController.clearCart();

                  // 🔹 Yape o BCP
                  if (metodoPago == "Yape" || metodoPago == "BCP") {
                    final paymentId = await paymentController.crearPago(
                      orderId: orderId,
                      userId: userId,
                      amount: totalFinal,
                      method: metodoPago,
                    );
                    Get.to(() => Pagosview(orderId: orderId, paymentId: paymentId));
                    return;
                  }

                  // 🔹 Mercado Pago (abre URL y marca pagado de inmediato)
                  if (metodoPago == "MercadoPago") {
                    final paymentId = await paymentController.crearPago(
                      orderId: orderId,
                      userId: userId,
                      amount: totalFinal,
                      method: "MercadoPago",
                    );

                    // ✅ Apenas se presiona el botón, ya se marca como pagado
                    await paymentController.simularPagoCompletado(paymentId);

                    // 🔹 Tu URL de preferencia (puede ser tu ngrok o una falsa de prueba)
                    final ngrokUrl = "https://somnambulistic-twitchingly-becki.ngrok-free.dev";

                    try {
                      final response = await http.post(
                        Uri.parse('$ngrokUrl/create_preference'),
                        headers: {"Content-Type": "application/json"},
                        body: jsonEncode({
                          "title": "Pedido $orderId",
                          "price": totalFinal.toDouble(),
                          "quantity": 1,
                          "orderId": orderId,
                        }),
                      );

                      if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        final initPoint = data['sandbox_init_point'] ?? data['init_point'];

                        if (initPoint != null && await canLaunchUrl(Uri.parse(initPoint))) {
                          await launchUrl(Uri.parse(initPoint), mode: LaunchMode.externalApplication);

                          // Mensaje de confirmación
                          Get.snackbar(
                            "Pago completado ✅",
                            "Tu pago fue registrado correctamente.",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green.shade600,
                            colorText: Colors.white,
                          );

                          Get.to(() => Pagosview(orderId: orderId, paymentId: paymentId));
                        } else {
                          Get.snackbar(
                            "Error",
                            "No se pudo abrir el enlace de Mercado Pago ❌",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade300,
                            colorText: Colors.white,
                          );
                        }
                      } else {
                        Get.snackbar(
                          "Error",
                          "Error desde el servidor (${response.statusCode}) ❌",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade300,
                          colorText: Colors.white,
                        );
                      }
                    } catch (e) {
                      Get.snackbar(
                        "Error",
                        "Error al abrir Mercado Pago: $e",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade300,
                        colorText: Colors.white,
                      );
                    }
                    return;
                  }

                  // 🔹 Contra entrega
                  Get.snackbar(
                    "Pedido realizado",
                    "Tu pedido fue registrado correctamente ✅",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  Get.off(() => const MisPedidosView());
                },
                child: const Text("Confirmar Pedido", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
