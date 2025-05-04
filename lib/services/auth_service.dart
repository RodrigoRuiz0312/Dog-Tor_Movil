import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  // Registro con email, password y username
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
    String nombre,
    String apellidos,
    String tipoUsuario,
    String? cedulaProfesional,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = {
        'username': username,
        'email': email,
        'nombre': nombre,
        'apellidos': apellidos,
        'tipoUsuario': tipoUsuario,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (tipoUsuario == 'Veterinario' && cedulaProfesional != null) {
        userData['cedulaProfesional'] = cedulaProfesional;
        userData['estado'] = 'pendiente'; // para revisión posterior
      }

      await _firestore.collection('users').doc(result.user!.uid).set(userData);

      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Error en registro: ${e.code} - ${e.message}");
      return null;
    }
  }

  // Login con username y password
  Future<User?> signInWithUsernameAndPassword(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      // Primero intenta hacer login directamente (asumiendo que usernameOrEmail podría ser un email)
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: usernameOrEmail,
        password: password,
      );

      // Verificar si es admin
      final isAdmin =
          await _firestore
              .collection('admin_roles')
              .doc(result.user!.uid)
              .get();

      // Obtener datos del usuario
      final userDoc =
          await _firestore.collection('users').doc(result.user!.uid).get();

      if (isAdmin.exists) {
        // Es admin, redirigirá al AdminPanel automáticamente
        return result.user;
      }

      // Lógica existente para veterinarios...
      if (userDoc['tipoUsuario'] == 'Veterinario') {
        switch (userDoc['estado']) {
          case 'pendiente':
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'pending-approval',
              message: 'Cuenta pendiente de aprobación',
            );
          case 'rechazado':
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'account-rejected',
              message: 'Cuenta rechazada',
            );
          case 'aceptado':
            break; // Permite el login
        }
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        // Si falla, intenta buscar el email asociado al username
        final query =
            await _firestore
                .collection('users')
                .where('username', isEqualTo: usernameOrEmail)
                .limit(1)
                .get();

        if (query.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Usuario no encontrado',
          );
        }

        final email = query.docs.first['email'];
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return result.user;
      }
      rethrow;
    }
  }

  // Obtener username del usuario actual
  Future<String?> getUserName(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc['nombre'] as String?; // O 'username' si prefieres
    } catch (e) {
      print("Error al obtener nombre: $e");
      return null;
    }
  }

  // Verificar si un username está disponible
  Future<bool> isUsernameAvailable(String username) async {
    final query =
        await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
    return query.docs.isEmpty;
  }

  // En AuthService
  Future<String?> getEmailByUsername(String username) async {
    try {
      final query =
          await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return query
          .docs
          .first['email']; // Devuelve el correo asociado al nombre de usuario
    } catch (e) {
      print("Error al obtener el correo del usuario: $e");
      return null;
    }
  }

  // En AuthService
  Future<bool> isAdmin(String uid) async {
    final doc = await _firestore.collection('admin_roles').doc(uid).get();
    return doc.exists; // True si el UID existe en la colección admin_roles
  }

  Future<DocumentSnapshot> getUserDoc(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }
}
