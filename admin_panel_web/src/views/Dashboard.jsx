// src/views/Dashboard.jsx
import React, { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import {
  fetchDashboardData,
  obtenerVentasPorDiaRealtime,
} from "../controllers/dashboardController";
import { handleLogout } from "../controllers/authController";
import { obtenerUsuarioPorId } from "../controllers/usercontroller";
import ProductsPanel from "./ProductsPanel";
import OrdersPanel from "../components/OrdersPanel";
import AdminChatPanel from "../components/AdminChatPanel";
import {
  escucharPedidosNuevos,
  escucharMensajesNuevos,
  escucharProductosBajos,
} from "../controllers/notificationController";
import { CSVLink } from "react-csv";

// ✅ Importamos los nuevos componentes reutilizables
import DashboardCard from "../components/DashboardCard";
import WeeklyTrendChart from "../components/WeeklyTrendChart";
import DashboardButton from "../components/DashboardButton";

// ✅ Import correcto del CSS
import "./Dashboard.css";

// ✅ Import del logo
import LogoMinik from "../assets/Logominik.png";

function Dashboard() {
  const [view, setView] = useState("general");

  const [pedidosPendientes, setPedidosPendientes] = useState(0);
  const [pedidosEntregados, setPedidosEntregados] = useState(0);
  const [pedidosEnCamino, setPedidosEnCamino] = useState(0);

  const [productosEnStock, setProductosEnStock] = useState(0);
  const [inventarioBajo, setInventarioBajo] = useState(0);
  const [ventasHoy, setVentasHoy] = useState(0);
  const [userName, setUserName] = useState("Admin");
  const [clientes, setClientes] = useState([]);
  const [ventasPorDia, setVentasPorDia] = useState([]);

  const [notificationsFromDB, setNotificationsFromDB] = useState([]);
  const [dismissedIds, setDismissedIds] = useState(() => new Set());
  const [notifOpen, setNotifOpen] = useState(false);
  const [diasAMostrar, setDiasAMostrar] = useState(7);

  const navigate = useNavigate();
  const adminId = localStorage.getItem("uid") || "admin";
  const mountedRef = useRef(true);
  const notifRef = useRef(null);

  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  useEffect(() => {
    const uid = localStorage.getItem("uid");
    if (uid) {
      obtenerUsuarioPorId(uid)
        .then((user) => {
          if (user) {
            const displayName = user.name || user.nombre || user.email || "Admin";
            setUserName(displayName);
          }
        })
        .catch((err) => console.error("Error al obtener usuario:", err));
    }

    const unsubscribe = fetchDashboardData({
      onProductos: ({ totalStock, bajoStock }) => {
        setProductosEnStock(totalStock);
        setInventarioBajo(bajoStock);
      },
      onPedidos: ({ pendientes, entregados, enCamino, ventasHoy }) => {
        setPedidosPendientes(pendientes);
        setPedidosEntregados(entregados);
        setPedidosEnCamino(enCamino);
        setVentasHoy(ventasHoy);
      },
      onClientes: (listaClientes) => setClientes(listaClientes),
      onError: console.error,
      onNotificacion: (msg) => console.log("Notificación dashboard:", msg),
    });

    const unsubscribeVentas = obtenerVentasPorDiaRealtime((data) => {
      setVentasPorDia(data);
    });

    const unsubPedidos = escucharPedidosNuevos((pedidos) => {
      setNotificationsFromDB((prev) => {
        const others = prev.filter((p) => p.tipo !== "pedido");
        const merged = [...others, ...pedidos];
        return merged.filter(Boolean).sort((a, b) => new Date(b.fecha) - new Date(a.fecha));
      });
    });

    const unsubMensajes = escucharMensajesNuevos(adminId, (mensajes) => {
      setDismissedIds((prev) => {
        const updated = new Set(prev);
        mensajes.forEach((m) => updated.delete(m.id));
        return updated;
      });

      setNotificationsFromDB((prev) => {
        const others = prev.filter((p) => p.tipo !== "mensaje");
        const merged = [...others, ...mensajes];
        return merged.filter(Boolean).sort((a, b) => new Date(b.fecha) - new Date(a.fecha));
      });
    });

    const unsubProductos = escucharProductosBajos((productos) => {
      setNotificationsFromDB((prev) => {
        const others = prev.filter((p) => p.tipo !== "producto");
        const merged = [...others, ...productos];
        return merged.filter(Boolean).sort((a, b) => new Date(b.fecha) - new Date(a.fecha));
      });
    });

    return () => {
      if (typeof unsubscribe === "function") unsubscribe();
      if (typeof unsubscribeVentas === "function") unsubscribeVentas();
      if (typeof unsubPedidos === "function") unsubPedidos();
      if (typeof unsubMensajes === "function") unsubMensajes();
      if (typeof unsubProductos === "function") unsubProductos();
    };
  }, [adminId]);

  // Cerrar panel de notificaciones al hacer clic fuera
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (notifRef.current && !notifRef.current.contains(event.target)) {
        setNotifOpen(false);
      }
    };

    if (notifOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [notifOpen]);

  const visibleNotifications = notificationsFromDB.filter((n) => !dismissedIds.has(n.id));
  const notifCount = visibleNotifications.reduce((total, n) => {
    if (n.tipo === "mensaje") {
      if (typeof n.cantidad === "number") return total + n.cantidad;
      if (Array.isArray(n.raw)) return total + n.raw.length;
    }
    return total + 1;
  }, 0);

  const handleDismissNotification = (id) => {
    setDismissedIds((prev) => new Set(prev).add(id));
  };

  const handleLogoutClick = async () => {
    try {
      await handleLogout();
      navigate("/login");
    } catch (error) {
      console.error("Error al cerrar sesión:", error);
    }
  };

  const cargarMasDias = () => setDiasAMostrar((prev) => prev + 7);

  const csvData = [
    ...ventasPorDia.map((v) => ({
      Día: v.fechaReal.toLocaleDateString("es-PE", { weekday: "long", day: "numeric", month: "long", year: "numeric" }),
      Total: v.total.toFixed(2),
    })),
    {
      Día: "Total General",
      Total: ventasPorDia.reduce((sum, v) => sum + v.total, 0).toFixed(2),
    },
  ];

  const renderView = () => {
    switch (view) {
      case "general":
        return (
          <>
            <div className="dashboard-grid">
              <DashboardCard title="Pedidos Pendientes" value={pedidosPendientes} icon="🛒" color="#85C744" />
              <DashboardCard title="Pedidos Entregados" value={pedidosEntregados} icon="✅" color="#85C744" />
              <DashboardCard title="Pedidos en Camino" value={pedidosEnCamino} icon="🚚" color="#EEDD39" />
              <DashboardCard title="Productos en Stock" value={productosEnStock} icon="📦" color="#85C744" />
              <DashboardCard title="Ventas de Hoy" value={`S/ ${ventasHoy.toFixed(2)}`} icon="💰" color="#85C744" />
            </div>

            <WeeklyTrendChart data={ventasPorDia} />

            <div className="sales-history">
              <h3>Historial de Ventas</h3>
              {ventasPorDia.length > 0 ? (
                <>
                  <table className="sales-table">
                    <thead>
                      <tr>
                        <th>Día</th>
                        <th>Fecha</th>
                        <th>Total (S/)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {ventasPorDia.slice(0, diasAMostrar).map((v) => (
                        <tr key={v.fechaReal}>
                          <td>{v.fechaReal.toLocaleDateString("es-PE", { weekday: "long" })}</td>
                          <td>{v.fechaReal.toLocaleDateString("es-PE")}</td>
                          <td>{v.total.toFixed(2)}</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot>
                      <tr>
                        <td colSpan="2"><strong>Total General</strong></td>
                        <td><strong>{ventasPorDia.reduce((sum, v) => sum + v.total, 0).toFixed(2)}</strong></td>
                      </tr>
                    </tfoot>
                  </table>
                  {diasAMostrar < ventasPorDia.length && (
                    <button onClick={cargarMasDias} className="load-more-btn">
                      Ver más días
                    </button>
                  )}
                  <CSVLink data={csvData} filename={`historial_ventas.csv`} className="export-btn">
                    Descargar Historial de ventas (CSV)
                  </CSVLink>
                </>
              ) : (
                <p>No hay registros de ventas aún.</p>
              )}
            </div>
          </>
        );
      case "products":
        return <ProductsPanel />;
      case "orders":
        return <OrdersPanel />;
      case "messages":
        return <AdminChatPanel adminId={adminId} clientes={clientes} />;
      default:
        return null;
    }
  };

  return (
    <div className="dashboard-container">
      <div className="dashboard-header">
        <div className="header-brand">
          <img src={LogoMinik} alt="Minik Logo" className="dashboard-logo" />
          <h2>MINIK APP</h2>
        </div>
        <div className="user-and-logout-container">
          <div className="notification-container" ref={notifRef}>
            <button onClick={() => setNotifOpen((s) => !s)} className="notification-bell">
              🔔 {notifCount > 0 && <span className="notification-count">{notifCount}</span>}
            </button>
            {notifOpen && (
              <div className="notification-dropdown">
                {visibleNotifications.length === 0 ? (
                  <div className="notification-empty">No hay notificaciones</div>
                ) : (
                  visibleNotifications
                    .slice()
                    .sort((a, b) => new Date(b.fecha) - new Date(a.fecha))
                    .map((n) => (
                      <div key={n.id} className={`notification-item ${n.tipo}`}>
                        <div>
                          <span style={{ fontWeight: 600 }}>
                            {n.tipo === "pedido" && "🛒 Pedido"}
                            {n.tipo === "mensaje" && "💬 Mensaje"}
                            {n.tipo === "producto" && "⚠️ Producto"}
                          </span>
                          <div>{n.mensaje}</div>
                          <small>{n.fecha ? new Date(n.fecha).toLocaleString() : ""}</small>
                        </div>
                        <button className="dismiss-btn" onClick={() => handleDismissNotification(n.id)}
                          >
                          ×
                        </button>
                      </div>
                    ))
                )}
              </div>
            )}
          </div>
          <span className="user-info">Hola, {userName}</span>
          <button onClick={handleLogoutClick} className="logout-button">Cerrar Sesión</button>
        </div>
      </div>

      <div className="dashboard-buttons">
        <DashboardButton label="General" onClick={() => setView("general")} />
        <DashboardButton label="Productos" onClick={() => setView("products")} />
        <DashboardButton label="Pedidos" onClick={() => setView("orders")} />
        <DashboardButton label="Mensajes" onClick={() => setView("messages")} />
      </div>

      <div className="dashboard-content-area">{renderView()}</div>
    </div>
  );
}

export default Dashboard;
