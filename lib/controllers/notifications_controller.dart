import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsController with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _notifications = [];
  int get unreadCount => _notifications.length;
  List<String> get notifications => _notifications;

  StreamSubscription? _messagesSub;
  StreamSubscription? _ordersSub;

  BuildContext? _context;

  /// Establecer contexto para mostrar SnackBars
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Iniciar listeners de mensajes y pedidos
  void iniciarListeners() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // 🔹 Mensajes no leídos
    _messagesSub = _db
        .collection("mensajes")
        .where("destinatarioId", isEqualTo: userId)
        .where("leido", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          addNotification("Nuevo mensaje del Administrador");
        }
      }
    });

    // 🔹 Pedidos del usuario
    _ordersSub = _db
        .collection("pedidos")
        .where("userId", isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final estado = change.doc['estado'] ?? "";
          String mensajeEstado = _formatearEstado(estado);
          if (mensajeEstado.isNotEmpty) {
            addNotification(
                "Pedido #${change.doc['displayId']}: $mensajeEstado");
          }
        }
      }
    });
  }

  /// Formatear estado del pedido a mensaje amigable
  String _formatearEstado(String estado) {
    switch (estado) {
      case "Pendiente":
        return "Tu pedido está pendiente";
      case "En camino":
        return "Tu pedido está en camino";
      case "Entregado":
        return "Tu pedido ha sido entregado";
      case "Pagado":
        return "Tu pedido ha sido pagado";
      default:
        return ""; // No notificar estados no importantes
    }
  }

  /// Agregar notificación y mostrar SnackBar
  void addNotification(String message) {
    _notifications.add(message);
    notifyListeners();
    if (_context != null) showSnackBar(message);
  }

  /// Marcar todas como leídas
  void markAllAsRead() {
    _notifications.clear();
    notifyListeners();
  }

  /// Mostrar SnackBar
  void showSnackBar(String message) {
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  /// Cancelar listeners
  void disposeListeners() {
    _messagesSub?.cancel();
    _ordersSub?.cancel();
  }
}
