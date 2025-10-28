// lib/views/chat/chat_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // ✅ para acceder al Provider
import '../../controllers/chat_controller.dart';
import '../../models/mensaje_model.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ChatController _chatController;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _chatId;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    // Esperamos que el Provider esté disponible en el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController = Provider.of<ChatController>(context, listen: false);
      _inicializarChat();
    });
  }

  Future<void> _inicializarChat() async {
    final id = await _chatController.getChatId();
    setState(() {
      _chatId = id;
      _cargando = false;
    });

    // Cuando el cliente abre el chat, marcamos mensajes como leídos
    if (id != null) {
      await _chatController.marcarMensajesComoLeidos();
    }
  }

  void _enviar() async {
    if (_controller.text.trim().isEmpty || _chatId == null) return;
    await _chatController.enviarMensaje(_controller.text.trim());
    _controller.clear();

    // Desplazarse automáticamente al último mensaje
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Escuchamos cambios del ChatController para actualizar UI (opcional)
    return Consumer<ChatController>(
      builder: (context, chatController, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Chat con el Administrador"),
            backgroundColor: Colors.green.shade700,
          ),
          body: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _chatId == null
                  ? const Center(child: Text("No se encontró admin."))
                  : Column(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<Mensaje>>(
                            stream: _chatController.obtenerMensajesStream(_chatId!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(child: Text("No hay mensajes aún."));
                              }

                              final mensajes = snapshot.data!;

                              // Scroll automático al último mensaje
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });

                              return ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                itemCount: mensajes.length,
                                itemBuilder: (context, index) {
                                  final mensaje = mensajes[index];
                                  final esMio = mensaje.remitenteId == _chatController.currentUserId;

                                  return Align(
                                    alignment: esMio
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: esMio ? Colors.green.shade400 : Colors.grey.shade300,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(esMio ? 12 : 0),
                                          topRight: Radius.circular(esMio ? 0 : 12),
                                          bottomLeft: const Radius.circular(12),
                                          bottomRight: const Radius.circular(12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            mensaje.texto,
                                            style: TextStyle(
                                              color: esMio ? Colors.white : Colors.black,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (mensaje.timestamp != null)
                                            Text(
                                              DateFormat('hh:mm a').format(mensaje.timestamp!),
                                              style: TextStyle(
                                                color: esMio ? Colors.white70 : Colors.black54,
                                                fontSize: 10,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        SafeArea(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            color: Colors.grey.shade100,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    decoration: const InputDecoration(
                                      hintText: "Escribe un mensaje...",
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (_) => _enviar(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send, color: Colors.green),
                                  onPressed: _enviar,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}
