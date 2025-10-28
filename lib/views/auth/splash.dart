import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login.dart';
import '../home/home.dart';
import '../home/RepartidorHomeview.dart';
import '../../models/user_models.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    // ⏳ Espera mientras se reproduce la animación
    await Future.delayed(const Duration(seconds: 3));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 🚪 No hay sesión → Ir al Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      // 🔍 Hay sesión activa → verificar datos en Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = doc.data();
      final userModel = UserModel(
        uid: user.uid,
        email: userData?['email'] ?? user.email ?? '',
        name: userData?['name'] ?? user.displayName ?? 'Usuario',
        role: userData?['role'] ?? 'cliente',
      );

      // 🎯 Redirigir según rol
      if (userModel.role == 'repartidor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RepartidorHomeView(user: userModel),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeView(user: userModel),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black54, Colors.greenAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🛒 Animación Lottie
              Lottie.asset(
                'assets/animations/shopping cart.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                "MINIK APP",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
