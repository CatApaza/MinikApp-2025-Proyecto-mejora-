import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // ✅ para acceder a ChatController
import '../home/home.dart';
import '../home/RepartidorHomeview.dart';
import 'registro.dart';
import 'reset_password.dart';
import 'package:minik_app_tania/widgets/password_field.dart';
import '../../models/user_models.dart';
import '../../controllers/chat_controller.dart'; // ✅ ChatController

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static bool allowAutoRedirect = true;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  void _checkIfLoggedIn() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null && LoginPage.allowAutoRedirect) {
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

        // 🔹 INICIAR EL LISTENER DE MENSAJES NO LEIDOS
        final chatController =
            Provider.of<ChatController>(context, listen: false);
        chatController.iniciarListenerMensajesNoLeidos();

        // 🔹 Redirección según rol
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
    });
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      duration: const Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showCustomSnackBar("⚠️ Por favor completa todos los campos",
          isError: true);
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final firebaseUser = cred.user!;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      final userData = doc.data();
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: userData?['email'] ?? firebaseUser.email ?? '',
        name: userData?['name'] ?? firebaseUser.displayName ?? 'Usuario',
        role: userData?['role'] ?? 'cliente',
      );

      _showCustomSnackBar("✅ Bienvenido, ${userModel.name}!", isError: false);

      LoginPage.allowAutoRedirect = true;

      // 🔹 INICIAR EL LISTENER DE MENSAJES NO LEIDOS DESPUÉS DEL LOGIN
      final chatController =
          Provider.of<ChatController>(context, listen: false);
      chatController.iniciarListenerMensajesNoLeidos();

      // 🔹 Redirección según rol
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
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case "invalid-email":
          errorMessage = "📧 El correo no es válido";
          break;
        case "user-not-found":
          errorMessage = "❌ Usuario no encontrado";
          break;
        case "wrong-password":
          errorMessage = "🔑 Contraseña incorrecta";
          break;
        case "user-disabled":
          errorMessage = "🚫 Usuario deshabilitado";
          break;
        default:
          errorMessage = "❌ Error al iniciar sesión. Inténtalo de nuevo";
      }

      _showCustomSnackBar(errorMessage, isError: true);
    } catch (e) {
      _showCustomSnackBar("❌ Error inesperado. Inténtalo otra vez",
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fondof.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Card(
                color: Colors.white,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 64, color: Colors.green.shade700),
                      const SizedBox(height: 12),
                      Text(
                        "MINIK APP",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Inicia sesión para continuar",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined,
                              color: Colors.green[700]),
                          labelText: "Correo",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      PasswordField(
                        controller: _passwordController,
                        label: "Contraseña",
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _login,
                          child: const Text(
                            "Iniciar Sesión",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ResetPasswordPage()),
                          );
                        },
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          LoginPage.allowAutoRedirect = false;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterView()),
                          );
                        },
                        child: Text(
                          "¿No tienes cuenta? Regístrate",
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
