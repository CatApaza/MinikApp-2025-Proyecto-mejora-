import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/mensaje_model.dart';

class ChatController with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  String? get currentUserId => _auth.currentUser?.uid;

  StreamSubscription? _unreadSubscription;

  ChatController() {
    // Inicializamos el listener si ya hay usuario activo
    if (currentUserId != null) {
      iniciarListenerMensajesNoLeidos();
    }
  }

  /// 🔹 Inicia el listener de mensajes no leídos del usuario actual
  void iniciarListenerMensajesNoLeidos() {
    // Cancelamos cualquier listener anterior
    _unreadSubscription?.cancel();

    final userId = currentUserId;
    if (userId == null) return;

    _unreadSubscription = _db
        .collection("mensajes")
        .where("destinatarioId", isEqualTo: userId)
        .where("leido", isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _unreadCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  /// 🔹 Detener listener (cuando se cierra sesión)
  void detenerListener() {
    _unreadSubscription?.cancel();
    _unreadSubscription = null;
    _unreadCount = 0;
    notifyListeners();
  }

  /// 🔹 Obtiene ID del admin
  Future<String?> getAdminId() async {
    final query = await _db
        .collection("users")
        .where("role", isEqualTo: "admin")
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first.id;
    return null;
  }

  /// 🔹 Genera chatId consistente
  Future<String?> getChatId() async {
    final adminId = await getAdminId();
    final userId = currentUserId;
    if (adminId == null || userId == null) return null;
    final ids = [adminId, userId]..sort();
    return ids.join("_");
  }

  /// 🔹 Enviar mensaje
  Future<void> enviarMensaje(String texto) async {
    final chatId = await getChatId();
    final userId = currentUserId;
    final adminId = await getAdminId();
    if (texto.trim().isEmpty || chatId == null || userId == null || adminId == null) return;

    await _db.collection("mensajes").add({
      "chatId": chatId,
      "remitenteId": userId,
      "destinatarioId": adminId,
      "texto": texto.trim(),
      "leido": false,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Stream de mensajes de un chat
  Stream<List<Mensaje>> obtenerMensajesStream(String chatId) {
    return _db
        .collection("mensajes")
        .where("chatId", isEqualTo: chatId)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Mensaje.fromMap(doc.id, doc.data())).toList());
  }

  /// 🔹 Marcar mensajes como leídos
  Future<void> marcarMensajesComoLeidos() async {
    final userId = currentUserId;
    if (userId == null) return;

    final snapshot = await _db
        .collection("mensajes")
        .where("destinatarioId", isEqualTo: userId)
        .where("leido", isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {"leido": true});
    }
    await batch.commit();

    _unreadCount = 0;
    notifyListeners();
  }
}
