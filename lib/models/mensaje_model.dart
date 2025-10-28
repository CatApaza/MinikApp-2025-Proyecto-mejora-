import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  final String id;
  final String remitenteId;
  final String destinatarioId;
  final String texto;
  final bool leido;       // ✅ campo para mensajes leídos
  final DateTime? timestamp;

  Mensaje({
    required this.id,
    required this.remitenteId,
    required this.destinatarioId,
    required this.texto,
    this.leido = false,    // por defecto falso
    this.timestamp,
  });

  // 🔹 Crear objeto desde Map de Firestore
  factory Mensaje.fromMap(String id, Map<String, dynamic> data) {
    final dynamic rawTs = data['timestamp'];
    DateTime? fecha;

    if (rawTs == null) {
      fecha = null;
    } else if (rawTs is Timestamp) {
      fecha = rawTs.toDate();
    } else if (rawTs is DateTime) {
      fecha = rawTs;
    } else if (rawTs is int) {
      fecha = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs is String) {
      fecha = DateTime.tryParse(rawTs);
    } else {
      fecha = null;
    }

    return Mensaje(
      id: id,
      remitenteId: data['remitenteId'] ?? '',
      destinatarioId: data['destinatarioId'] ?? '',
      texto: data['texto'] ?? '',
      leido: data['leido'] ?? false,
      timestamp: fecha,
    );
  }

  // 🔹 Convertir objeto a Map para Firestore
  Map<String, dynamic> toMap({bool useServerTimestampIfNull = true}) {
    return {
      'remitenteId': remitenteId,
      'destinatarioId': destinatarioId,
      'texto': texto,
      'leido': leido,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : (useServerTimestampIfNull ? FieldValue.serverTimestamp() : null),
    }..removeWhere((k, v) => v == null);
  }
}
