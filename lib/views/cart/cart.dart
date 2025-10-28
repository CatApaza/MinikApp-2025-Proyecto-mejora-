import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
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

class CartView extends StatelessWidget {
  const CartView({super.key});

  void _confirmPurchase(BuildContext context, CartController cartController) {
    final orderController = OrderController();
    final paymentController = PaymentController();

    String metodoEntrega = "Delivery";
    String direccion = "";
    String metodoPago = "Contra entrega";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double getTotal() {
              double total = cartController.totalPrice;
              if (metodoEntrega == "Delivery") total *= 1.10;
              return total;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.shopping_cart_checkout,
                      color: Colors.green.shade700, size: 26),
                  const SizedBox(width: 8),
                  const Text("Confirmar compra"),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartController.items.length,
                        itemBuilder: (context, index) {
                          final item = cartController.items[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Image.network(item.product.imageUrl,
                                width: 40, height: 40, fit: BoxFit.cover),
                            title: Text(item.product.nombre,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text("Cantidad: ${item.quantity}"),
                            trailing: Text(
                              "S/ ${(item.product.precio * item.quantity).toStringAsFixed(2)}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Total: S/ ${getTotal().toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Método de entrega:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: metodoEntrega,
                        items: ["Delivery", "Recojo en tienda"]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => metodoEntrega = value);
                        },
                      ),
                      if (metodoEntrega == "Delivery")
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Dirección de entrega",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => direccion = value,
                        ),
                      const SizedBox(height: 10),
                      const Text("Método de pago:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: metodoPago,
                        items: ["Contra entrega", "Yape", "BCP", "MercadoPago"]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => metodoPago = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    final userId = FirebaseAuth.instance.currentUser!.uid;
                    double totalFinal = getTotal();

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
                        "Algún producto está agotado o no hay stock suficiente ❌",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade300,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    final orderWithId = OrderModel(
                      id: orderId,
                      userId: order.userId,
                      items: order.items,
                      total: order.total,
                      metodoEntrega: order.metodoEntrega,
                      metodoPago: order.metodoPago,
                      estado: order.estado,
                      fecha: order.fecha,
                      direccion: order.direccion,
                    );

                    cartController.clearCart();
                    Navigator.of(context).pop();

                    // 🔹 Pago Yape o BCP
                    if (metodoPago == "Yape" || metodoPago == "BCP") {
                      final paymentId = await paymentController.crearPago(
                        orderId: orderWithId.id,
                        userId: userId,
                        amount: orderWithId.total,
                        method: metodoPago,
                      );
                      Get.to(() => Pagosview(
                          orderId: orderWithId.id, paymentId: paymentId));
                      return;
                    }

                    // 🔹 Pago con Mercado Pago (espera 5 segundos antes de marcar pagado)
                    if (metodoPago == "MercadoPago") {
                      final paymentId = await paymentController.crearPago(
                        orderId: orderWithId.id,
                        userId: userId,
                        amount: orderWithId.total,
                        method: "MercadoPago",
                      );

                      try {
                        final response = await http.post(
                          Uri.parse('https://somnambulistic-twitchingly-becki.ngrok-free.dev/create_preference'),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "title": "Pedido ${orderWithId.id}",
                            "price": orderWithId.total,
                            "quantity": 1,
                            "orderId": orderWithId.id,
                          }),
                        );

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          final initPoint = data['sandbox_init_point'] ?? data['init_point'];

                          if (initPoint != null &&
                              initPoint.isNotEmpty &&
                              await canLaunchUrl(Uri.parse(initPoint))) {
                            // ✅ Abre Mercado Pago
                            await launchUrl(Uri.parse(initPoint),
                                mode: LaunchMode.externalApplication);

                            // ⏱ Espera 5 segundos antes de marcar pagado
                            await Future.delayed(const Duration(seconds: 5));

                            // 🔹 Ahora sí marcar como pagado
                            await paymentController.simularPagoCompletado(paymentId);

                            Get.snackbar(
                              "Pago completado ✅",
                              "Tu pago fue registrado correctamente.",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green.shade600,
                              colorText: Colors.white,
                            );

                            Get.off(() => const MisPedidosView());
                          } else {
                            Get.snackbar(
                              "Error",
                              "No se pudo abrir la URL de Mercado Pago ❌",
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
                          "No se pudo procesar MercadoPago: $e",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade300,
                          colorText: Colors.white,
                        );
                      }
                      return;
                    }

                    // 🔹 Pago Contra Entrega
                    Get.snackbar(
                      "Pedido realizado",
                      "Tu orden fue registrada correctamente ✅",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    Get.off(() => const MisPedidosView());
                  },
                  label: const Text("Confirmar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Provider.of<CartController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Carrito"),
        backgroundColor: Colors.green.shade700,
      ),
      body: cartController.items.isEmpty
          ? const Center(child: Text("Tu carrito está vacío"))
          : ListView.builder(
              itemCount: cartController.items.length,
              itemBuilder: (context, index) {
                final item = cartController.items[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Image.network(
                      item.product.imageUrl,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(item.product.nombre),
                    subtitle: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            cartController.decrementItemQuantity(item.product);
                          },
                        ),
                        Text("${item.quantity}",
                            style: const TextStyle(fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            cartController.incrementItemQuantity(item.product);
                          },
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "S/ ${(item.product.precio * item.quantity).toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            cartController.removeItem(item.product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: Colors.white),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(
                                            "${item.product.nombre} eliminado del carrito")),
                                  ],
                                ),
                                backgroundColor: Colors.blue.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 2),
                                margin: const EdgeInsets.all(12),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartController.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total: S/ ${cartController.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _confirmPurchase(context, cartController);
                    },
                    child: const Text("Comprar"),
                  ),
                ],
              ),
            ),
    );
  }
}
