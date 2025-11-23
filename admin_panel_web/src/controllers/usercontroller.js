import { doc, getDoc, collection, onSnapshot } from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";

// Obtener un usuario por ID
export const obtenerUsuarioPorId = async (uid) => {
  try {
    const userRef = doc(db, "users", uid);
    const userSnap = await getDoc(userRef);

    if (userSnap.exists()) {
      return { id: userSnap.id, ...userSnap.data() };
    }
    return null;
  } catch (error) {
    console.error("Error al obtener usuario:", error);
    return null;
  }
};

// Obtener todos los clientes en tiempo real
export const obtenerClientes = (callback, onError) => {
  try {
    const q = collection(db, "users"); // todos los usuarios
    return onSnapshot(
      q,
      (snapshot) => {
        const users = snapshot.docs
          .map((doc) => ({ id: doc.id, ...doc.data() }))
          .filter((u) => u.role === "cliente"); // solo clientes
        callback(users);
      },
      onError
    );
  } catch (error) {
    if (onError) onError(error);
    else console.error("Error al obtener clientes:", error);
  }
};
