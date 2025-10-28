import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_models.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/notifications_controller.dart'; // ✅ Añadido
import '../cart/cart.dart';
import 'product_search_delegate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../orders/MisPedidos.dart';
import '../chat/chatpage.dart';
import '../Pagos/Mipagos.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeView extends StatefulWidget {
  final UserModel user;

  const HomeView({super.key, required this.user});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final List<String> categories = [
    "Todos",
    "Lácteos",
    "Dulces",
    "Bebidas",
    "Verduras",
    "Panes",
    "Frutas",
    "Menestras",
    "Carnes",
    "Aseo",
    "Otros"
  ];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatController = Provider.of<ChatController>(context, listen: false);
      chatController.iniciarListenerMensajesNoLeidos();

      // Inicializar contexto para notificaciones
      final notificationsController =
          Provider.of<NotificationsController>(context, listen: false);
      notificationsController.setContext(context);
      notificationsController.iniciarListeners(); // 🔹 Aquí se activan los listeners
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();

    final chatController = Provider.of<ChatController>(context, listen: false);
    chatController.detenerListener();

    final notificationsController =
        Provider.of<NotificationsController>(context, listen: false);
    notificationsController.disposeListeners();

    super.dispose();
  }

  void _startAutoScroll() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= 3) _currentPage = 0;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade600, size: 28),
              const SizedBox(width: 8),
              Text("Cerrar sesión",
                  style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("¿Estás seguro de que deseas cerrar sesión?",
              style: TextStyle(fontSize: 16)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
              child: const Text("Cancelar"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, size: 18, color: Colors.white),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.of(context).pop();
                await _auth.signOut();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false);
              },
              label: const Text("Sí, salir"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Provider.of<CartController>(context);
    final chatController = Provider.of<ChatController>(context);
    final homeController = Provider.of<HomeController>(context);
    final notificationsController = Provider.of<NotificationsController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Image.asset(
                "assets/images/Logominik.png",
                height: 36,
                width: 36,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Bienvenido, ${widget.user.name}",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              homeController.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Colors.green.shade700,
            ),
            onPressed: () {
              homeController.toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.grey.shade700),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(homeController),
              );
            },
          ),

          // ✅ CAMPANITA DE NOTIFICACIONES
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.green),
                onPressed: () {
                  // Abrir vista de notificaciones o marcar como leídas
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => NotificationSheet(),
                  );
                },
              ),
              if (notificationsController.unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${notificationsController.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            icon: Icon(Icons.logout, color: Colors.red.shade700),
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50.withOpacity(0.8),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Categorías
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          homeController.filterByCategory(categories[index]);
                        },
                        child: Chip(
                          label: Text(categories[index]),
                          backgroundColor:
                              Colors.green.shade100.withOpacity(0.6),
                          labelStyle: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500),
                          side: BorderSide(color: Colors.green.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          avatar: Icon(_getCategoryIcon(categories[index]),
                              color: Colors.green.shade700, size: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Carrusel de promociones
              SizedBox(
                height: 160,
                child: PageView(
                  controller: _pageController,
                  children: [
                    _buildPromotionCard(
                      title: "Compra 2 y llévate 3",
                      subtitle: "Solo por esta semana",
                      imageUrl:
                          "https://static.mercadonegro.pe/wp-content/uploads/2024/01/11190510/PORTAL-16-1.jpg",
                      onPressed: () {
                        homeController.filterByCategory("Dulces");
                      },
                    ),
                    _buildPromotionCard(
                      title: "Envío gratis hoy",
                      subtitle: "No te lo pierdas",
                      imageUrl:
                          "https://www.sorpresasperu.com/imagenes/productos/torta2013-6.jpg",
                      onPressed: () {
                        homeController.filterByCategory("Panes");
                      },
                    ),
                    _buildPromotionCard(
                      title: "Semana de frutas",
                      subtitle: "Descuentos hasta 50%",
                      imageUrl:
                          "https://thumbs.dreamstime.com/z/cartel-de-la-venta-del-descuento-con-la-fruta-fresca-89108437.jpg",
                      onPressed: () {
                        homeController.filterByCategory("Frutas");
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Productos
              if (homeController.filteredProducts.isEmpty)
                const Center(child: Text('No hay productos disponibles.'))
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: homeController.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = homeController.filteredProducts[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: Image.network(product.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image,
                                      size: 50, color: Colors.grey);
                                }),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(product.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      "S/ ${product.precio.toStringAsFixed(2)}",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w600)),
                                  IconButton(
                                    icon: Icon(Icons.add_shopping_cart,
                                        size: 20,
                                        color: Colors.green.shade700),
                                    onPressed: () {
                                      cartController.addItem(product);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade600,
        child: const FaIcon(FontAwesomeIcons.whatsapp,
            color: Colors.white, size: 28),
        onPressed: () async {
          final Uri whatsappUrl = Uri.parse(
              "https://wa.me/51935964167?text=¡Hola!%20Quiero%20más%20información%20sobre%20un%20pedido.%20");
          if (await canLaunchUrl(whatsappUrl)) {
            await launchUrl(whatsappUrl,
                mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No se pudo abrir WhatsApp")),
            );
          }
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              homeController.loadProducts();
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MisPedidosView()),
              );
              break;
            case 2:
              chatController.marcarMensajesComoLeidos();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MisPagos()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartView()),
              );
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Inicio'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Mis pedidos'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.message),
                if (chatController.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10)),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${chatController.unreadCount}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Mensajes',
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.payment), label: 'Pagos'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (cartController.itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10)),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cartController.itemCount}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Carrito',
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Lácteos":
        return Icons.local_drink;
      case "Dulces":
        return Icons.emoji_food_beverage;
      case "Bebidas":
        return Icons.local_drink;
      case "Verduras":
        return Icons.grass;
      case "Panes":
        return Icons.bakery_dining;
      case "Frutas":
        return Icons.apple;
      case "Carnes":
        return Icons.set_meal;
      case "Menestras":
        return Icons.spa;
      case "Aseo":
        return Icons.clean_hands;
      case "Otros":
        return Icons.category;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _buildPromotionCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Ver productos"),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 Hoja de notificaciones en bottom sheet
class NotificationSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final notificationsController = Provider.of<NotificationsController>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Notificaciones",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green.shade700)),
          const SizedBox(height: 10),
          Expanded(
            child: notificationsController.notifications.isEmpty
                ? const Center(child: Text("No tienes notificaciones"))
                : ListView.builder(
                    itemCount: notificationsController.notifications.length,
                    itemBuilder: (context, index) {
                      final note = notificationsController.notifications[index];
                      return ListTile(
                        leading: const Icon(Icons.notifications),
                        title: Text(note),
                      );
                    },
                  ),
          ),
          ElevatedButton(
            onPressed: () {
              notificationsController.markAllAsRead();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: const Text("Marcar todas como leídas"),
          ),
        ],
      ),
    );
  }
}
