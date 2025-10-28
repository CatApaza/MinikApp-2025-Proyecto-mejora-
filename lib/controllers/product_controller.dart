import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

// Referencia a la colección 'productos' en Firestore
final CollectionReference productosCollection =
    FirebaseFirestore.instance.collection('productos');

// Escucha la colección de productos en tiempo real
Stream<List<Product>> getProducts() {
  return productosCollection.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  });
}
