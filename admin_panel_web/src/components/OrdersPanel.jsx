// src/components/OrdersPanel.jsx
import React, { useEffect, useState } from "react";
import {
  obtenerPedidos,
  actualizarEstadoPedido,
  obtenerRepartidores,
  asignarRepartidor,
} from "../controllers/orderController";
import "./OrdersPanel.css";

const OrdersPanel = () => {
  const [orders, setOrders] = useState([]);
  const [repartidores, setRepartidores] = useState([]);
  const [filtroEstado, setFiltroEstado] = useState(""); // estado seleccionado

  useEffect(() => {
    const unsubscribe = obtenerPedidos(
      (pedidos) => setOrders(pedidos),
      (err) => console.error(err),
      filtroEstado || null
    );
    obtenerRepartidores().then(setRepartidores);
    return () => unsubscribe && unsubscribe();
  }, [filtroEstado]); // 🔹 escucha cambios en el filtro

  const formatearFecha = (timestamp) => {
    if (!timestamp) return "Sin fecha";
    const fecha = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return fecha.toLocaleDateString("es-PE", {
      weekday: "short",
      day: "2-digit",
      month: "short",
    });
  };

  const formatearTotal = (total) => {
    if (!total) return "S/ 0.00";
    return new Intl.NumberFormat("es-PE", {
      style: "currency",
      currency: "PEN",
    }).format(total);
  };

  return (
    <div className="orders-panel">
      <h2>📦 Pedidos</h2>

      {/* 🔹 Filtro por estado */}
      <div style={{ marginBottom: "16px" }}>
        <label htmlFor="filtroEstado">🔍 Filtrar por estado: </label>
        <select
          id="filtroEstado"
          value={filtroEstado}
          onChange={(e) => setFiltroEstado(e.target.value)}
        >
          <option value="">Todos</option>
          <option value="Pendiente">Pendientes</option>
          <option value="En camino">En camino</option>
          <option value="Entregado">Entregados</option>
        </select>
      </div>

      {orders.length === 0 ? (
        <p>No hay pedidos</p>
      ) : (
        <div className="orders-grid">
          {orders.map((order) => (
            <div key={order.id} className="order-card">
              <h3>Pedido de {order.nombreCliente}</h3>
              <p><strong>ID:</strong> {order.id}</p>

              <p>
                <strong>Estado:</strong>{" "}
                <span
                  className={`estado-badge ${
                    order.estado === "Pendiente"
                      ? "estado-pendiente"
                      : order.estado === "En camino"
                      ? "estado-camino"
                      : "estado-entregado"
                  }`}
                >
                  {order.estado}
                </span>
              </p>

              <p><strong>Total:</strong> {formatearTotal(order.total)}</p>
              <p><strong>Método de pago:</strong> {order.metodoPago || "No especificado"}</p>
              <p><strong>Método de entrega:</strong> {order.metodoEntrega || "No especificado"}</p>

              {order.metodoPago?.toLowerCase() === "yape" && (
                <div className="alerta-yape">
                  ⚠️ <strong>Verifique el comprobante Yape</strong>
                  Asegúrese de que el cliente haya enviado el monto correcto antes de marcar este pedido como entregado.
                </div>
              )}

              <p><strong>Fecha:</strong> {formatearFecha(order.fecha)}</p>
              <p>
                <strong>📍 Dirección:</strong>{" "}
                {order.metodoEntrega === "Delivery"
                  ? order.direccion || "Sin dirección"
                  : "Recojo en tienda"}
              </p>

              {order.metodoEntrega === "Delivery" && (
                <div style={{ margin: "8px 0" }}>
                  {order.repartidorId ? (
                    <p>
                      ✅ Pedido asignado a:{" "}
                      {repartidores.find((r) => r.id === order.repartidorId)?.name || "Repartidor"}
                    </p>
                  ) : order.estado === "Pendiente" ? (
                    <select
                      value=""
                      onChange={(e) => {
                        const repartidor = repartidores.find((r) => r.id === e.target.value);
                        if (repartidor)
                          asignarRepartidor(order.id, repartidor.id, repartidor.name, setOrders);
                      }}
                    >
                      <option value="">Asignar repartidor</option>
                      {repartidores.map((r) => (
                        <option key={r.id} value={r.id}>
                          {r.name}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <p>Pedido sin repartidor asignado</p>
                  )}
                </div>
              )}

              <p><strong>Productos:</strong></p>
              <ul>
                {order.items?.map((item, index) => (
                  <li key={index}>
                    {item.nombre} x {item.cantidad} – S/ {item.precio}
                  </li>
                ))}
              </ul>

              <div className="order-buttons">
                {order.metodoEntrega === "Delivery" && order.estado === "Pendiente" && (
                  <button
                    className="btn-camino"
                    onClick={() => actualizarEstadoPedido(order.id, "En camino")}
                  >
                    En camino
                  </button>
                )}
                {order.estado !== "Entregado" && (
                  <button
                    className="btn-entregado"
                    onClick={() => actualizarEstadoPedido(order.id, "Entregado")}
                  >
                    Entregado
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default OrdersPanel;
