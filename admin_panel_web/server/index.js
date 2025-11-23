// server/index.js
import express from "express";
import cors from "cors";
import fetch from "node-fetch";
import fs from "fs";
import path from "path";
import admin from "firebase-admin";

const app = express();
app.use(cors());
app.use(express.json());

// 🔹 Inicializar Firebase Admin
const serviceAccountPath = path.resolve("./serviceAccountKey.json");
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf-8"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

console.log("✅ Firebase Admin inicializado correctamente");

// 🔹 Token de Mercado Pago (sandbox)
const ACCESS_TOKEN = "APP_USR-8796087898192661-101123-8d56ba25c58c9098d8eb321418ce4ad0-2919985519";

// 🔹 URL pública de Ngrok
const baseUrl = "https://somnambulistic-twitchingly-becki.ngrok-free.dev";

// 🔹 Crear preferencia
app.post("/create_preference", async (req, res) => {
  try {
    const { title, price, quantity, orderId } = req.body;

    if (!title || !price || !quantity || !orderId) {
      return res.status(400).json({ error: "Faltan campos obligatorios" });
    }

    const bodyPreference = {
      items: [
        {
          title,
          quantity: Number(quantity),
          currency_id: "PEN",
          unit_price: Number(price),
        },
      ],
      back_urls: {
        success: `${baseUrl}/success?orderId=${orderId}`,
        failure: `${baseUrl}/failure?orderId=${orderId}`,
        pending: `${baseUrl}/pending?orderId=${orderId}`,
      },
      auto_return: "approved",
      external_reference: orderId,
      notification_url: `${baseUrl}/webhook`,
    };

    console.log("📦 Preference body:", JSON.stringify(bodyPreference, null, 2));

    const response = await fetch("https://api.mercadopago.com/checkout/preferences", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${ACCESS_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(bodyPreference),
    });

    const data = await response.json();
    console.log("✅ Respuesta MP:", data);

    res.json({ sandbox_init_point: data.sandbox_init_point });
  } catch (error) {
    console.error("❌ Error al crear preferencia:", error);
    res.status(500).json({ error: "Error al crear preferencia" });
  }
});

// 🔹 Webhook para actualizar el estado del pedido
app.post("/webhook", async (req, res) => {
  try {
    console.log("🔔 Webhook recibido:", req.body);

    const { type, data } = req.body;

    // Solo procesamos si el webhook trae un pago real
    if (type === "payment" && data?.id) {
      const paymentId = data.id;

      // Consultar información del pago
      const response = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${ACCESS_TOKEN}`,
        },
      });

      const payment = await response.json();
      console.log("💳 Datos del pago MP:", payment);

      const externalRef = payment.external_reference;
      const status = payment.status; // approved, pending, rejected...

      if (status === "approved" && externalRef) {
        const pedidosRef = admin.firestore().collection("pedidos");
        const snapshot = await pedidosRef.where("displayId", "==", externalRef).get();

        if (!snapshot.empty) {
          snapshot.forEach(async (doc) => {
            await pedidosRef.doc(doc.id).update({ estado: "Pagado" });
            console.log(`✅ Pedido ${externalRef} actualizado a Pagado`);
          });
        } else {
          console.log(`⚠️ No se encontró pedido con displayId ${externalRef}`);
        }
      }
    }

    res.sendStatus(200);
  } catch (err) {
    console.error("❌ Error en webhook:", err);
    res.sendStatus(500);
  }
});

// 🔹 Rutas de prueba
app.get("/success", (req, res) => res.send("✅ Pago exitoso"));
app.get("/failure", (req, res) => res.send("❌ Pago fallido"));
app.get("/pending", (req, res) => res.send("⏳ Pago pendiente"));

// 🔹 Iniciar servidor
app.listen(5000, "0.0.0.0", () => {
  console.log(`✅ Servidor MercadoPago sandbox en ${baseUrl}`);
});
