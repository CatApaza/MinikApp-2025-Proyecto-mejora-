import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'views/auth/splash.dart';
import 'views/home/RepartidorHomeview.dart';
import 'models/user_models.dart';
import 'controllers/cart_controller.dart';
import 'controllers/Repartidorcontroller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/home_controller.dart'; // ✅ Importar para el tema dinámico
import 'controllers/notifications_controller.dart'; // 🔹 NUEVO
import 'config/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
        Provider(create: (_) => RepartidorController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(
            create: (_) =>
                HomeController(user: UserModel(uid: '', name: '', email: ''))),
        ChangeNotifierProvider(create: (_) => NotificationsController()), // 🔹 NUEVO
      ],
      child: Consumer<HomeController>(
        builder: (context, homeController, _) {
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final cartController =
                  Provider.of<CartController>(context, listen: false);
              final notificationsController =
                  Provider.of<NotificationsController>(context, listen: false);

              // 🔹 Asignar contexto para SnackBars
              WidgetsBinding.instance.addPostFrameCallback((_) {
                notificationsController.setContext(context);
              });

              if (snapshot.connectionState == ConnectionState.active) {
                final user = snapshot.data;
                if (user == null) {
                  cartController.clearCart();
                  _lastUserId = null;
                } else {
                  if (_lastUserId != null && _lastUserId != user.uid) {
                    cartController.clearCart();
                  }
                  _lastUserId = user.uid;
                }
              }

              return GetMaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Minik App',
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: homeController.isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
                home: const SplashPage(),
                routes: {
                  '/login': (context) => const SplashPage(),
                },
              );
            },
          );
        },
      ),
    );
  }
}

// 🔹 Redirección al Home del repartidor
void abrirRepartidorHome(BuildContext context, User firebaseUser) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => RepartidorHomeView(
        user: UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? "",
          name: firebaseUser.displayName ?? "Repartidor",
          role: "repartidor",
        ),
      ),
    ),
  );
}
