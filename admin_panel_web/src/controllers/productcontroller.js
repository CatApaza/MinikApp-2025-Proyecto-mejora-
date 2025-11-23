import { collection, onSnapshot, addDoc, doc, updateDoc, deleteDoc } from "firebase/firestore";
import { db } from "../firebase/firebaseConfig";
import Product from "../models/product.js";

const productsCollectionRef = collection(db, "productos");

// Escucha cambios en tiempo real
export function obtenerProductos(callback, onError) {
  const unsubscribe = onSnapshot(
    productsCollectionRef,
    (snapshot) => {
      const products = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      callback(products);
    },
    (error) => {
      console.error("Error al obtener productos:", error);
      onError(error);
    }
  );
  return unsubscribe;
}

// Agrega un nuevo producto
export async function agregarProducto(product) {
  try {
    await addDoc(productsCollectionRef, product.toFirestore());
  } catch (e) {
    console.error("Error al agregar producto: ", e);
    throw e;
  }
}

// Actualiza un producto existente
export async function actualizarProducto(id, updatedData) {
  try {
    const docRef = doc(db, "productos", id);
    await updateDoc(docRef, updatedData);
  } catch (e) {
    console.error("Error al actualizar producto: ", e);
    throw e;
  }
}

// Elimina un producto
export async function eliminarProducto(id) {
  try {
    const docRef = doc(db, "productos", id);
    await deleteDoc(docRef);
  } catch (e) {
    console.error("Error al eliminar producto: ", e);
    throw e;
  }
}
