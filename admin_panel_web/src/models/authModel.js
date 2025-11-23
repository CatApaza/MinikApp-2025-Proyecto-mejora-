// src/models/authModel.js
import { getAuth, signInWithEmailAndPassword, signOut, createUserWithEmailAndPassword } from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

// Registro de administrador
export const registerWithEmail = async (email, password, name) => {
  const auth = getAuth();
  const userCredential = await createUserWithEmailAndPassword(auth, email, password);
  const uid = userCredential.user.uid;

  // Crear documento en Firestore
  await setDoc(doc(db, "users", uid), {
    name: name,
    email: email,
    role: "admin",
    createdAt: new Date(),
  });

  return userCredential.user;
};

// Login
export const loginWithEmail = async (email, password) => {
  const auth = getAuth();
  const userCredential = await signInWithEmailAndPassword(auth, email, password);
  return userCredential.user;
};

// Logout
export const logout = async () => {
  const auth = getAuth();
  await signOut(auth);
};
