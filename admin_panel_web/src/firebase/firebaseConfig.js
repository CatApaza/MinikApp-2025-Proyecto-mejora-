// src/firebase/firebaseConfig.js
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyCZT-8kMjNYqR4qA4m9VyCTzbcv37s-6go",
  authDomain: "minik-app-bc154.firebaseapp.com",
  projectId: "minik-app-bc154",
  storageBucket: "minik-app-bc154.appspot.com", // ✅ corregido
  messagingSenderId: "163752744140",
  appId: "1:163752744140:web:7afc7a9310c4e60b781e69",
  measurementId: "G-36SG3WGPHS",
};

const app = initializeApp(firebaseConfig);

export const db = getFirestore(app);
export const auth = getAuth(app);
export { app };
