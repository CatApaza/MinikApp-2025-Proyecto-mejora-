import {
  collection,
  addDoc,
  serverTimestamp,
  query,
  where,
  orderBy,
  onSnapshot,
  getDocs,
  updateDoc,
  doc,
} from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

// 🔑 Generar ID de chat único
export const generarChatId = (id1, id2) => [id1, id2].sort().join("_");

// 📤 Enviar mensaje
export const enviarMensaje = async (remitenteId, destinatarioId, texto) => {
  const chatId = generarChatId(remitenteId, destinatarioId);

  await addDoc(collection(db, "mensajes"), {
    chatId,
    remitenteId,
    destinatarioId,
    texto,
    leido: false, // 👈 SIEMPRE en false al enviar
    timestamp: serverTimestamp(),
  });
};

// 📥 Escuchar mensajes en tiempo real
export const escucharMensajes = (id1, id2, callback) => {
  const chatId = generarChatId(id1, id2);

  const q = query(
    collection(db, "mensajes"),
    where("chatId", "==", chatId),
    orderBy("timestamp", "asc")
  );

  return onSnapshot(q, (snapshot) => {
    const mensajes = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        timestamp: data.timestamp || { toDate: () => new Date() },
      };
    });
    callback(mensajes);
  });
};

// 🔄 Marcar mensajes como leídos (solo los del cliente)
export const marcarMensajesLeidos = async (adminId, clienteId) => {
  const chatId = generarChatId(adminId, clienteId);

  const q = query(
    collection(db, "mensajes"),
    where("chatId", "==", chatId),
    where("leido", "==", false),
    where("remitenteId", "==", clienteId) // 👈 solo mensajes que mandó el cliente
  );

  const snapshot = await getDocs(q);
  const batch = snapshot.docs.map(docItem =>
    updateDoc(doc(db, "mensajes", docItem.id), { leido: true })
  );

  await Promise.all(batch);
};
