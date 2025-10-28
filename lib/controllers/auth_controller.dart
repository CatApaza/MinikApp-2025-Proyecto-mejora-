import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:minik_app_tania/models/user_models.dart';

class AuthController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// LOGIN
  /// Devuelve un UserModel si todo OK, o String con mensaje de error si falla.
  static Future<dynamic> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return "Error al obtener el usuario";

      // Traemos los datos desde Firestore
      final doc = await _db.collection("users").doc(user.uid).get();

      if (!doc.exists) {
        return UserModel(
          uid: user.uid,
          name: user.displayName ?? "",
          email: user.email ?? "",
        );
      }

      return UserModel.fromMap(doc.data()!);
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (_) {
      return 'Error inesperado. Intenta de nuevo.';
    }
  }

  /// REGISTER
  /// Devuelve un UserModel si todo OK, o String con mensaje de error si falla.
  static Future<dynamic> register(
      String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) return "Error al crear usuario";

      await user.updateDisplayName(name);

      // Creamos el modelo
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
      );

      // Guardamos en Firestore
      await _db.collection("users").doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (_) {
      return 'Error inesperado. Intenta de nuevo.';
    }
  }

  /// RESET PASSWORD
  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseAuthError(e);
    } catch (_) {
      return 'Error inesperado. Intenta de nuevo.';
    }
  }

  /// SIGN OUT
  static Future<void> signOut() => _auth.signOut();

  /// CURRENT USER como modelo
  static Future<UserModel?> currentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection("users").doc(user.uid).get();
    if (!doc.exists) {
      return UserModel(
        uid: user.uid,
        name: user.displayName ?? "",
        email: user.email ?? "",
      );
    }

    return UserModel.fromMap(doc.data()!);
  }

  /// Mapear errores de Firebase
  static String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Correo inválido';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'El correo ya está en uso';
      case 'weak-password':
        return 'Contraseña muy débil';
      case 'user-disabled':
        return 'Cuenta deshabilitada';
      default:
        return e.message ?? 'Error de autenticación';
    }
  }
}
