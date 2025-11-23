import React, { useState, useEffect } from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import Dashboard from "./views/Dashboard";
import Login from "./views/Login";
import Register from "./views/Register";
import { getAuth, onAuthStateChanged } from "firebase/auth";
import { app } from "./firebase/firebaseConfig";

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const auth = getAuth(app);

  useEffect(() => {
    // Escucha el estado de autenticación de Firebase en tiempo real.
    // Esto se ejecuta al iniciar la app y cada vez que el usuario cambia (inicia/cierra sesión).
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setLoading(false);
    });

    // Devuelve una función de limpieza para detener la escucha al desmontar el componente.
    return () => unsubscribe();
  }, [auth]);

  // Si la aplicación aún está comprobando el estado de autenticación, muestra un mensaje de carga.
  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        Cargando...
      </div>
    );
  }

  return (
    <Router>
      <Routes>
        {/*
          Ruta Raíz: Redirige al panel si hay un usuario logueado,
          o a la página de inicio de sesión si no lo hay.
        */}
        <Route path="/" element={user ? <Navigate to="/dashboard" /> : <Navigate to="/login" />} />
        
        {/*
          Rutas Públicas: Accesibles solo si NO hay un usuario autenticado.
          Redirigen al panel si ya se ha iniciado sesión.
        */}
        <Route path="/login" element={user ? <Navigate to="/dashboard" /> : <Login />} />
        <Route path="/register" element={user ? <Navigate to="/dashboard" /> : <Register />} />

        {/*
          Ruta Privada: Accesible solo si SÍ hay un usuario autenticado.
          Redirige a la página de inicio de sesión si no lo hay.
        */}
        <Route path="/dashboard" element={user ? <Dashboard /> : <Navigate to="/login" />} />
      </Routes>
    </Router>
  );
}

export default App;
