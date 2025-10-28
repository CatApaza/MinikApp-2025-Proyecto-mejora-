import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/payment_controller.dart';

class Pagosview extends StatefulWidget {
  final String orderId;
  final String paymentId;

  const Pagosview({super.key, required this.orderId, required this.paymentId});

  @override
  State<Pagosview> createState() => _PagosviewState();
}

class _PagosviewState extends State<Pagosview> {
  final PaymentController _paymentController = PaymentController();

  @override
  Widget build(BuildContext context) {
    print("📌 Pagosview abierta con:");
    print("➡️ orderId: ${widget.orderId}");
    print("➡️ paymentId: ${widget.paymentId}");

    if (widget.paymentId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Text(
            "❌ No se recibió el ID de pago correctamente.\nVerifica el flujo de navegación.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar con Yape'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pagos')
              .doc(widget.paymentId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                  child: Text("Cargando información del pago..."));
            }

            final doc = snapshot.data!;
            final data = doc.data() as Map<String, dynamic>?;

            if (data == null) {
              return const Center(
                  child: Text("No se encontró información del pago."));
            }

            final reference = (data['reference'] ?? '').toString().trim();
            final amount = (data['amount'] ?? 0).toDouble();
            final method = (data['method'] ?? 'Yape').toString();
            final status = (data['status'] ?? 'pending').toString();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Escanea este código QR para pagar con Yape",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 🟢 Aquí reemplazamos el QR generado por tu imagen de QR
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/qr_yape.png', // 📸 Ruta de tu imagen
                      width: 240,
                      height: 240,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text('Referencia: $reference',
                      style: const TextStyle(fontSize: 16)),
                  Text('Monto: S/ ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16)),
                  Text('Método: $method',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // Botón para simular o mostrar estado
                  if (status == 'pending')
                    ElevatedButton(
                      onPressed: () async {
                        await _paymentController
                            .simularPagoCompletado(widget.paymentId);

                        // SnackBar bonito
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '✅ ¡Pago realizado con éxito!',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              elevation: 6,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }

                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                      ),
                      child: const Text('Marcar como Pagado'),
                    )
                  else
                    Chip(
                      label: Text('Estado: $status',
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.green.shade700,
                    ),

                  const SizedBox(height: 20),
                  const Text(
                    "👉 Escanea este QR con la app Yape.\n"
                    "👉 O yapea al siguiente numero 935964167.\n"
                    "El pago se actualizará manualmente o con el botón de arriba.\n"
                    "OJO: envie le comprobante de yape al whatsap \n"
                    "o mesajes directos de la app.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
