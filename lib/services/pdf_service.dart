import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';

class PdfService {
  static Future<Uint8List> generateOrderInvoice(OrderModel order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // 🔹 ENCABEZADO
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MiniMarket LibertMarket',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text('RUC: 20123456789'),
                  pw.Text('Av. Principal 123 - Arequipa, Perú'),
                  pw.Text('Teléfono: +51 999 888 777'),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.green800),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'BOLETA DE VENTA',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('N° ${order.id}'),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // 🔹 INFORMACIÓN DEL PEDIDO
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE8F5E9),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('📅 Fecha: ${order.fecha.toLocal()}'),
                pw.Text('🚚 Entrega: ${order.metodoEntrega}'),
                pw.Text('💳 Método de pago: ${order.metodoPago}'),
                if (order.direccion != null && order.direccion!.isNotEmpty)
                  pw.Text('📍 Dirección: ${order.direccion}'),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // 🔹 DETALLE DE PRODUCTOS
          pw.Text(
            'Detalle del Pedido',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),

          ...order.items.map((i) {
            final subtotal =
                ((i['precio'] ?? 0) * (i['cantidad'] ?? 0)).toDouble();
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text(i['nombre'] ?? 'Producto')),
                  pw.Text(
                      '${i['cantidad']} x S/ ${(i['precio'] ?? 0).toStringAsFixed(2)}'),
                  pw.Text('S/ ${subtotal.toStringAsFixed(2)}'),
                ],
              ),
            );
          }),

          pw.Divider(),

          // 🔹 TOTAL
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL: S/ ${order.total.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
          ),

          pw.SizedBox(height: 25),

          // 🔹 PIE DE PÁGINA
          pw.Center(
            child: pw.Text(
              '¡Gracias por su compra! 💚',
              style: pw.TextStyle(fontSize: 14),
            ),
          ),
          pw.Center(
            child: pw.Text(
              'MiniMarket LibertMarket - Arequipa, Perú',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> printBytes(Uint8List bytes,
      {String filename = 'boleta.pdf'}) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }
}
