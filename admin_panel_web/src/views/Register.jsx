import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { handleRegister } from "../controllers/authController";
import "./Login.css";

function Register() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState(""); // Nombre del admin
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      // 🔹 Guardar usuario y obtener el UID
      const userCredential = await handleRegister(email, password, name);

      // 🔹 Guardar UID en localStorage
      localStorage.setItem("uid", userCredential.user.uid);

      navigate("/dashboard");
    } catch (err) {
      setError(
        "Error al crear la cuenta. Intenta con otro correo o contraseña más fuerte."
      );
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        <h2>Registrar Administrador</h2>
        <form onSubmit={handleSubmit} className="login-form">
          <div className="input-group">
            <label>Nombre</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Nombre completo"
              required
            />
          </div>
          <div className="input-group">
            <label>Correo Electrónico</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@example.com"
              required
            />
          </div>
          <div className="input-group">
            <label>Contraseña</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>
          <button type="submit" disabled={loading}>
            {loading ? "Creando cuenta..." : "Registrar"}
          </button>
        </form>
        {error && <p className="error-message">{error}</p>}
      </div>
    </div>
  );
}

export default Register;
