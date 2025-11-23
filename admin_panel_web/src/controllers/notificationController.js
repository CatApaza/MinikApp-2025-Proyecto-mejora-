// src/controllers/notificationController.js
import { 
  collection, query, where, orderBy, onSnapshot, getDocs, getDoc, doc 
} from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

/** 🔔 Escuchar nuevos pedidos en tiempo real */
export function escucharPedidosNuevos(callback) {
  const q = query(collection(db, "pedidos"), where("estado", "==", "Pendiente"));
  const unsubscribe = onSnapshot(q, async (snapshot) => {
    const nuevos = await Promise.all(snapshot.docs.map(async (docSnap) => {
      const data = docSnap.data();

      // 🔹 Obtener nombre del cliente, priorizando `nombreCliente`, si no buscar por userId
      let nombreCliente = data.nombreCliente;
      if (!nombreCliente && data.userId) {
        try {
          const userSnap = await getDoc(doc(db, "users", data.userId));
          if (userSnap.exists()) {
            nombreCliente = userSnap.data().name || "Usuario desconocido";
          } else {
            nombreCliente = "Usuario desconocido";
          }
        } catch (e) {
          console.warn("Error al obtener nombre del usuario:", e);
          nombreCliente = "Usuario desconocido";
        }
      }

      return {
        id: docSnap.id,
        tipo: "pedido",
        mensaje: ` ${data.displayId} de ${nombreCliente}: S/ ${data.total?.toFixed(2) ?? 0}`,
        fecha: data.fechaCreacion?.toDate?.() || new Date(),
        raw: data,
      };
    }));
    callback(nuevos);
  });
  return unsubscribe;
}

/** 💬 Escuchar mensajes no leídos agrupados por remitente */
export async function escucharMensajesNuevos(adminId, callback) {
  const mensajesRef = collection(db, "mensajes");

  const q = query(
    mensajesRef,
    where("destinatarioId", "==", adminId),
    where("leido", "==", false)
  );

  // 1️⃣ Traer mensajes existentes no leídos
  const snapshotInicial = await getDocs(q);
  procesarMensajes(snapshotInicial.docs, callback);

  // 2️⃣ Escuchar cambios en tiempo real
  const unsubscribe = onSnapshot(q, (snapshot) => {
    procesarMensajes(snapshot.docs, callback);
  });

  return unsubscribe;
}

/** 🔹 Procesar mensajes: agrupar por remitente y generar notificaciones */
async function procesarMensajes(docs, callback) {
  const mensajes = docs.map((docSnap) => ({
    id: docSnap.id,
    ...docSnap.data(),
  }));

  // Agrupar por remitenteId
  const agrupados = {};
  for (const m of mensajes) {
    const remitenteId = m.remitenteId ?? "desconocido";
    if (!agrupados[remitenteId]) agrupados[remitenteId] = [];
    agrupados[remitenteId].push(m);
  }

  // Generar notificaciones con contador y nombre del remitente
  const notificaciones = await Promise.all(
    Object.entries(agrupados).map(async ([remitenteId, msgs]) => {
      let remitenteNombre = "Usuario desconocido";

      try {
        const userSnap = await getDoc(doc(db, "users", remitenteId));
        if (userSnap.exists()) {
          remitenteNombre = userSnap.data().name || remitenteNombre;
        }
      } catch (e) {
        console.warn("Error al obtener remitente:", e);
      }

      // Ordenar mensajes por fecha (más reciente primero)
      msgs.sort((a, b) => b.timestamp?.toDate?.() - a.timestamp?.toDate?.());

      return {
        id: remitenteId,
        tipo: "mensaje",
        mensaje: `Mensaje de ${remitenteNombre} (${msgs.length})`,
        cantidad: msgs.length,
        fecha: msgs[0].timestamp?.toDate?.() || new Date(),
        raw: msgs,
      };
    })
  );

  // Ordenar notificaciones por fecha del último mensaje
  notificaciones.sort((a, b) => b.fecha - a.fecha);

  callback(notificaciones);
}

/** ⚠️ Escuchar productos con bajo stock */
export function escucharProductosBajos(callback) {
  const q = query(collection(db, "productos"), where("stock", "<=", 5));
  const unsubscribe = onSnapshot(q, (snapshot) => {
    const nuevos = snapshot.docs.map((docSnap) => {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        tipo: "producto",
        mensaje: `Stock bajo: ${data.nombre ?? "Producto"} (${data.stock ?? 0})`,
        fecha: new Date(),
        raw: data,
      };
    });
    callback(nuevos);
  });
  return unsubscribe;
}
