import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/notifications_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationsController = Provider.of<NotificationsController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text(
          "Notificaciones",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: "Marcar todas como leídas",
            onPressed: () => notificationsController.markAllAsRead(),
          ),
        ],
      ),
      body: notificationsController.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No hay notificaciones.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notificationsController.notifications.length,
              itemBuilder: (context, index) {
                final notif = notificationsController.notifications[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Colors.green.shade100,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.shade100,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.notifications, color: Colors.green, size: 28),
                      ),
                      title: Text(
                        notif,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                      onTap: () {
                        // Opcional: puedes agregar acción al tocar la notificación
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
