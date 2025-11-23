import React, { useState, useEffect, useRef } from "react";
import { enviarMensaje, escucharMensajes, marcarMensajesLeidos } from "../controllers/messageController";
import "./chat.css";

const Chat = ({ userId, adminId }) => {
  const [mensajes, setMensajes] = useState([]);
  const [mensaje, setMensaje] = useState("");
  const mensajesEndRef = useRef(null);

  useEffect(() => {
    if (!userId || !adminId) return;

    // 🔹 Marcar mensajes como leídos al abrir el chat
    const marcarLeidos = async () => {
      await marcarMensajesLeidos(adminId, userId);
    };
    marcarLeidos();

    const unsubscribe = escucharMensajes(adminId, userId, (msgs) => {
      setMensajes(msgs);
    });

    return () => unsubscribe();
  }, [userId, adminId]);

  useEffect(() => {
    mensajesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [mensajes]);

  const handleSend = async () => {
    if (!mensaje.trim()) return;
    await enviarMensaje(adminId, userId, mensaje.trim(), false); // mensajes del admin ya leídos
    setMensaje("");
  };

  return (
    <div className="chat-container">
      {/* Historial */}
      <div className="chat-messages">
        {mensajes.length > 0 ? (
          mensajes.map((m) => (
            <div
              key={m.id}
              className={`chat-message ${m.remitenteId === adminId ? "user" : "admin"}`}
            >
              <div className={`message-bubble ${m.remitenteId === adminId ? "user" : "admin"}`}>
                {m.texto}
                <div className="message-time">
                  {m.timestamp?.toDate
                    ? new Date(m.timestamp.toDate()).toLocaleTimeString([], {
                        hour: "2-digit",
                        minute: "2-digit",
                      })
                    : ""}
                </div>
              </div>
            </div>
          ))
        ) : (
          <p className="chat-empty">No hay mensajes todavía</p>
        )}
        <div ref={mensajesEndRef} />
      </div>

      {/* Input */}
      <div className="chat-input-container">
        <input
          type="text"
          value={mensaje}
          onChange={(e) => setMensaje(e.target.value)}
          placeholder="Escribe un mensaje..."
          className="chat-input"
          onKeyDown={(e) => e.key === "Enter" && handleSend()}
        />
        <button onClick={handleSend} className="chat-send-btn">
          ➤
        </button>
      </div>
    </div>
  );
};

export default Chat;
