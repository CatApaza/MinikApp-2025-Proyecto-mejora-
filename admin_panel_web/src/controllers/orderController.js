import { collection, onSnapshot, query, orderBy, doc, updateDoc, getDocs, where } from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";
import Order from "../models/Order";

// Obtener todos los pedidos o por estado
export const obtenerPedidos = (onSuccess, onError, estadoFiltro = null) => {
  try {
    const pedidosRef = collection(db, "pedidos");
    let q;

    if (estadoFiltro) {
      // Filtrar por estado si se proporciona
      q = query(pedidosRef, where("estado", "==", estadoFiltro), orderBy("fecha", "desc"));
    } else {
      // Traer todos
      q = query(pedidosRef, orderBy("fecha", "desc"));
    }

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const pedidos = snapshot.docs.map((doc) => {
          const data = doc.data();
          return new Order({ id: doc.id, ...data });
        });
        onSuccess(pedidos);
      },
      (err) => onError && onError(err)
    );

    return unsubscribe;
  } catch (error) {
    if (onError) onError(error);
    return null;
  }
};

// Actualizar estado del pedido
export const actualizarEstadoPedido = async (pedidoId, nuevoEstado) => {
  try {
    const pedidoRef = doc(db, "pedidos", pedidoId);
    await updateDoc(pedidoRef, { estado: nuevoEstado });
    console.log(`Pedido ${pedidoId} actualizado a ${nuevoEstado}`);
  } catch (error) {
    console.error("Error al actualizar estado:", error);
  }
};

// Obtener repartidores
export const obtenerRepartidores = async () => {
  try {
    const repsRef = collection(db, "users");
    const snapshot = await getDocs(repsRef);
    return snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(u => u.role === "repartidor");
  } catch (error) {
    console.error("Error al obtener repartidores:", error);
    return [];
  }
};

// Asignar repartidor y actualizar UI local
export const asignarRepartidor = async (pedidoId, repartidorId, repartidorName, setOrders) => {
  try {
    const pedidoRef = doc(db, "pedidos", pedidoId);
    await updateDoc(pedidoRef, { repartidorId });
    console.log(`Pedido ${pedidoId} asignado a ${repartidorName}`);
    alert(`✅ Pedido asignado a ${repartidorName}`);

    setOrders(prev =>
      prev.map(p => p.id === pedidoId ? { ...p, repartidorId } : p)
    );
  } catch (error) {
    console.error("Error al asignar repartidor:", error);
  }
};

// Obtener pedidos de un repartidor
export const obtenerPedidosRepartidor = (repartidorId, onSuccess, onError) => {
  try {
    const pedidosRef = collection(db, "pedidos");
    const q = query(pedidosRef, where("repartidorId", "==", repartidorId), orderBy("fecha", "desc"));

    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const pedidos = snapshot.docs.map(doc => new Order({ id: doc.id, ...doc.data() }));
        onSuccess(pedidos);
      },
      (err) => onError && onError(err)
    );

    return unsubscribe;
  } catch (error) {
    if (onError) onError(error);
    return null;
  }
};
