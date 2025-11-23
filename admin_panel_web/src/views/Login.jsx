import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { loginWithEmail } from "../models/authModel";
import "./Login.css";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      // 🔹 Iniciar sesión
      const userCredential = await loginWithEmail(email, password);
      
      // 🔹 Guardar UID en localStorage para que Dashboard pueda jalar el nombre
      localStorage.setItem("uid", userCredential.uid);

      // 🔹 Redirigir al dashboard
      navigate("/dashboard");
    } catch (e) {
      setError(
        "Correo o contraseña incorrectos. Por favor, inténtalo de nuevo."
      );
      console.error("Error al iniciar sesión:", e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <h2>Iniciar Sesión</h2>
        <p className="login-subtitle">Panel de Administración</p>
        <form onSubmit={handleLogin} className="login-form">
          <div className="input-group">
            <label htmlFor="email">Correo Electrónico</label>
            <input
              type="email"
              id="email"
              placeholder="admin@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="input-group">
            <label htmlFor="password">Contraseña</label>
            <input
              type="password"
              id="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <button type="submit" disabled={loading}>
            {loading ? "Cargando..." : "Entrar"}
          </button>
        </form>
        {error && <p className="error-message">{error}</p>}
        <p className="redirect-text">
          ¿No tienes una cuenta?{" "}
          <button
            className="link-button"
            onClick={() => navigate("/register")}
          >
            Regístrate aquí
          </button>
        </p>
      </div>
    </div>
  );
};

export default Login;
