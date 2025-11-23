import { obtenerProductos } from "./productcontroller.js";
import { obtenerPedidos } from "./orderController";
import { obtenerClientes } from "./usercontroller";
import { collection, onSnapshot } from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

/**
 * Controlador principal del Dashboard.
 * Escucha cambios en productos, pedidos y clientes, y calcula métricas clave.
 */
export const fetchDashboardData = (callbacks) => {
  const { onProductos, onPedidos, onClientes, onError, onNotificacion } = callbacks;

  // --- 🔹 Productos ---
  const unsubscribeProducts = obtenerProductos(
    (snapshot) => {
      try {
        const listaProductos = Array.isArray(snapshot)
          ? snapshot
          : snapshot.docs?.map((doc) => ({ id: doc.id, ...doc.data() })) || [];

        const totalStock = listaProductos.reduce(
          (sum, p) => sum + (Number(p.stock) || 0),
          0
        );
        const bajoStock = listaProductos.filter(
          (p) => (Number(p.stock) || 0) < 10
        ).length;

        onProductos?.({ totalStock, bajoStock });

        if (bajoStock > 0) {
          onNotificacion?.(`⚠️ Hay ${bajoStock} productos con stock bajo.`);
        }
      } catch (error) {
        console.error("Error al procesar productos:", error);
        onError?.(error);
      }
    },
    (error) => {
      console.error("Error al obtener productos:", error);
      onError?.(error);
    }
  );

  // --- 🔹 Pedidos ---
  const unsubscribeOrders = obtenerPedidos(
    (snapshot) => {
      try {
        const listaPedidos = Array.isArray(snapshot)
          ? snapshot
          : snapshot.docs?.map((doc) => ({ id: doc.id, ...doc.data() })) || [];

        const pendientes = listaPedidos.filter(
          (p) => p.estado?.toString().trim().toLowerCase() === "pendiente"
        ).length;

        const entregados = listaPedidos.filter(
          (p) => p.estado?.toString().trim().toLowerCase() === "entregado"
        ).length;

        const enCamino = listaPedidos.filter(
          (p) => p.estado?.toString().trim().toLowerCase() === "en camino"
        ).length;

        const hoy = new Date();
        const ventasHoy = listaPedidos
          .filter((p) => {
            if (!p.fecha?.seconds) return false;
            const fechaPedido = new Date(p.fecha.seconds * 1000);
            return (
              fechaPedido.getDate() === hoy.getDate() &&
              fechaPedido.getMonth() === hoy.getMonth() &&
              fechaPedido.getFullYear() === hoy.getFullYear()
            );
          })
          .reduce((sum, p) => sum + (Number(p.total) || 0), 0);

        onPedidos?.({ pendientes, entregados, enCamino, ventasHoy });

        if (pendientes > 0) {
          onNotificacion?.(`🛒 Hay ${pendientes} pedidos pendientes.`);
        }
      } catch (error) {
        console.error("Error al procesar pedidos:", error);
        onError?.(error);
      }
    },
    (error) => {
      console.error("Error al obtener pedidos:", error);
      onError?.(error);
    }
  );

  // --- 🔹 Clientes ---
  const unsubscribeClientes = obtenerClientes(
    (snapshot) => {
      try {
        const listaClientes = Array.isArray(snapshot)
          ? snapshot
          : snapshot.docs?.map((doc) => ({ id: doc.id, ...doc.data() })) || [];
        onClientes?.(listaClientes);
      } catch (error) {
        console.error("Error al procesar clientes:", error);
        onError?.(error);
      }
    },
    (error) => {
      console.error("Error al obtener clientes:", error);
      onError?.(error);
    }
  );

  return () => {
    if (typeof unsubscribeProducts === "function") unsubscribeProducts();
    if (typeof unsubscribeOrders === "function") unsubscribeOrders();
    if (typeof unsubscribeClientes === "function") unsubscribeClientes();
  };
};

/**
 * --- 🔸 Escuchar ventas por día en tiempo real ---
 */
export const obtenerVentasPorDiaRealtime = (callback, onError) => {
  try {
    const pedidosRef = collection(db, "pedidos");

    const unsubscribe = onSnapshot(
      pedidosRef,
      (snapshot) => {
        const ventasMap = {};

        snapshot.forEach((doc) => {
          const data = doc.data();
          if (data.fecha?.seconds && data.total) {
            const fecha = new Date(data.fecha.seconds * 1000);
            const dia = fecha.toLocaleDateString("es-PE", {
              weekday: "short",
              day: "numeric",
              month: "short",
            });

            if (!ventasMap[dia]) {
              ventasMap[dia] = { total: 0, fechaReal: fecha };
            }
            ventasMap[dia].total += Number(data.total);
          }
        });

        const ventasArray = Object.entries(ventasMap)
          .map(([dia, data]) => ({
            dia,
            total: data.total,
            fechaReal: data.fechaReal,
          }))
          .sort((a, b) => b.fechaReal - a.fechaReal);

        callback(ventasArray);
      },
      (error) => {
        console.error("Error al escuchar ventas por día:", error);
        onError?.(error);
      }
    );

    return unsubscribe;
  } catch (error) {
    console.error("Error al configurar escucha de ventas:", error);
    onError?.(error);
    return () => {};
  }
};
