// src/controllers/authController.js
import { registerWithEmail, logout } from "../models/authModel";
import { doc, setDoc } from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

// Registrar usuario y guardar en Firestore
export async function handleRegister(email, password, name) {
  if (!email || !password || !name) {
    throw new Error("Correo, contraseña y nombre son obligatorios.");
  }
  try {
    // Crear usuario en Firebase Auth
    const userCredential = await registerWithEmail(email, password, name);

    // Guardar UID en localStorage
    localStorage.setItem("uid", userCredential.uid);

    return userCredential;
  } catch (error) {
    console.error("Fallo de registro:", error.message);
    throw error;
  }
}

// Cerrar sesión
export async function handleLogout() {
  try {
    await logout();
    localStorage.removeItem("uid");
  } catch (error) {
    console.error("Error al cerrar sesión:", error.message);
    throw error;
  }
}
