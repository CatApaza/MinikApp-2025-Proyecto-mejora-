import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_models.dart';
import '../../models/order_model.dart';
import '../../controllers/Repartidorcontroller.dart';

class RepartidorHomeView extends StatelessWidget {
  final UserModel user;
  final RepartidorController controller = RepartidorController();

  RepartidorHomeView({super.key, required this.user});

  // 🔹 Función para cerrar sesión
  void _cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5F9), // Fondo claro
      appBar: AppBar(
        title: const Text('Pedidos asignados'),
        backgroundColor: const Color(0xFF4CAF50), // Verde principal
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: controller.obtenerPedidosAsignados(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No tienes pedidos asignados',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ));
          }

          final pedidos = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];

              return Card(
                color: Colors.green.shade50, // Tarjeta verde suave
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pedido ID: ${pedido.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Estado: ${pedido.estado}',
                          style: TextStyle(
                              color: pedido.estado == 'Entregado'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Total: S/ ${pedido.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Dirección: ${pedido.direccion ?? "No disponible"}',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Productos:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      ...pedido.items.map((item) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Text(
                                '${item['nombre']} x ${item['cantidad']} – S/ ${item['precio']}'),
                          )),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (pedido.estado == 'Pendiente')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange),
                              onPressed: () => controller.actualizarEstadoPedido(
                                  pedido.id, 'En camino'),
                              child: const Text('En camino'),
                            ),
                          const SizedBox(width: 8),
                          if (pedido.estado == 'En camino')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              onPressed: () => controller.actualizarEstadoPedido(
                                  pedido.id, 'Entregado'),
                              child: const Text('Entregado'),
                            ),
                        ],
                      ),
                    ],
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
