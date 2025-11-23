import React, { useEffect, useState } from "react";
import { getDocs, collection, query, where } from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";
import Chat from "./Chat";
import { escucharMensajes, marcarMensajesLeidos } from "../controllers/messageController";
import "./AdminChatPanel.css";

const AdminChatPanel = () => {
  const [users, setUsers] = useState([]);
  const [selectedUserId, setSelectedUserId] = useState(null);
  const [adminId, setAdminId] = useState(null);
  const [unreadCounts, setUnreadCounts] = useState({});
  const [searchTerm, setSearchTerm] = useState("");

  // 🔹 Obtener admin
  useEffect(() => {
    const fetchAdminId = async () => {
      const q = query(collection(db, "users"), where("role", "==", "admin"));
      const snapshot = await getDocs(q);
      if (!snapshot.empty) setAdminId(snapshot.docs[0].id);
    };
    fetchAdminId();
  }, []);

  // 🔹 Obtener clientes
  useEffect(() => {
    const fetchUsers = async () => {
      const querySnapshot = await getDocs(collection(db, "users"));
      const clientes = querySnapshot.docs
        .filter(doc => doc.data().role === "cliente")
        .map(doc => ({ id: doc.id, ...doc.data() }));
      setUsers(clientes);
    };
    fetchUsers();
  }, []);

  // 🔹 Contador de mensajes no leídos en tiempo real
  useEffect(() => {
    if (!adminId || users.length === 0) return;

    const unsubscribes = users.map(user => {
      return escucharMensajes(adminId, user.id, (msgs) => {
        const noLeidos = msgs.filter(m => !m.leido && m.remitenteId === user.id).length;
        setUnreadCounts(prev => ({ ...prev, [user.id]: noLeidos }));
      });
    });

    return () => unsubscribes.forEach(u => u());
  }, [users, adminId]);

  // 🔹 Seleccionar cliente y marcar mensajes como leídos
  const handleSelectUser = async (userId) => {
    setSelectedUserId(userId);
    if (adminId && userId) {
      await marcarMensajesLeidos(adminId, userId);
      setUnreadCounts(prev => ({ ...prev, [userId]: 0 }));
    }
  };

  // 🔹 Filtrar usuarios por búsqueda
  const filteredUsers = users.filter(user => {
    const searchLower = searchTerm.toLowerCase();
    const nombre = (user.nombre || "").toLowerCase();
    const email = (user.email || "").toLowerCase();
    return nombre.includes(searchLower) || email.includes(searchLower);
  });

  // 🔹 Ordenar usuarios: primero los que tienen mensajes nuevos
  const sortedUsers = [...filteredUsers].sort((a, b) => {
    const unreadA = unreadCounts[a.id] || 0;
    const unreadB = unreadCounts[b.id] || 0;
    
    // Si ambos tienen mensajes no leídos, ordenar por cantidad (más mensajes primero)
    if (unreadA > 0 && unreadB > 0) {
      return unreadB - unreadA;
    }
    
    // Los que tienen mensajes no leídos van primero
    if (unreadA > 0) return -1;
    if (unreadB > 0) return 1;
    
    // Si ninguno tiene mensajes no leídos, mantener orden original
    return 0;
  });

  return (
    <div className="admin-chat-wrapper">
      <div className="admin-chat-panel">
        {/* Lista de clientes */}
        <div className="clients-list">
          <div className="clients-header">
            <h4>💬 Mensajes</h4>
            <span className="total-clients">{users.length}</span>
          </div>
          
          {/* Buscador */}
          <div className="search-container">
            <input
              type="text"
              className="search-input"
              placeholder="🔍 Buscar cliente..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            {searchTerm && (
              <button 
                className="clear-search"
                onClick={() => setSearchTerm("")}
              >
                ✕
              </button>
            )}
          </div>

          {sortedUsers.map(user => (
            <div
              key={user.id}
              className={`client-item ${selectedUserId === user.id ? "active" : ""}`}
              onClick={() => handleSelectUser(user.id)}
            >
              <div className="client-avatar">
                {(user.nombre || user.email).charAt(0).toUpperCase()}
              </div>
              <div className="client-info">
                <span className="client-name">{user.nombre || user.email}</span>
                {unreadCounts[user.id] > 0 && (
                  <span className="client-status">Nuevo mensaje</span>
                )}
              </div>
              {unreadCounts[user.id] > 0 && (
                <span className="unread-badge">{unreadCounts[user.id]}</span>
              )}
            </div>
          ))}
        </div>

        {/* Panel de chat */}
        <div className="chat-panel">
          {selectedUserId ? (
            adminId ? (
              <Chat userId={selectedUserId} adminId={adminId} />
            ) : (
              <div className="chat-placeholder">
                <div className="placeholder-icon">⏳</div>
                <p>Cargando admin...</p>
              </div>
            )
          ) : (
            <div className="chat-placeholder">
              <div className="placeholder-icon">💬</div>
              <p>Selecciona un cliente para iniciar la conversación</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AdminChatPanel;
