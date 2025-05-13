import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //String? cachedProfileImageUrl;

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
    print("=== Inicio de login ===");
    print("Username o email recibido: $usernameOrEmail");
    print(
      "Password recibido: ${'*' * password.length}",
    ); // evita mostrarlo completo

    try {
      // Intento 1: Asumimos que es un email
      print("Intentando login directo con FirebaseAuth...");

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: usernameOrEmail,
        password: password,
      );

      print("Login con email exitoso. UID: ${result.user!.uid}");

      // Verificar si es admin
      final isAdminDoc =
          await _firestore
              .collection('admin_roles')
              .doc(result.user!.uid)
              .get();
      print("¿Es admin?: ${isAdminDoc.exists}");

      // Obtener datos del usuario
      final userDoc =
          await _firestore.collection('users').doc(result.user!.uid).get();
      print("Tipo de usuario: ${userDoc['tipoUsuario']}");

      if (isAdminDoc.exists) {
        print("Usuario es administrador. Acceso permitido.");
        return result.user;
      }

      if (userDoc['tipoUsuario'] == 'Veterinario') {
        print("Estado del veterinario: ${userDoc['estado']}");
        switch (userDoc['estado']) {
          case 'pendiente':
            await _auth.signOut();
            print("Cuenta pendiente de aprobación. Se cerró sesión.");
            throw FirebaseAuthException(
              code: 'pending-approval',
              message: 'Cuenta pendiente de aprobación',
            );
          case 'rechazado':
            await _auth.signOut();
            print("Cuenta rechazada. Se cerró sesión.");
            throw FirebaseAuthException(
              code: 'account-rejected',
              message: 'Cuenta rechazada',
            );
          case 'aceptado':
            print("Veterinario aprobado. Acceso permitido.");
            break;
        }
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Error en login directo: ${e.code} - ${e.message}");

      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        print(
          "Intentando buscar el email asociado al username '$usernameOrEmail'...",
        );

        final query =
            await _firestore
                .collection('users')
                .where('username', isEqualTo: usernameOrEmail)
                .limit(1)
                .get();

        if (query.docs.isEmpty) {
          print("Username no encontrado en base de datos.");
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Usuario no encontrado',
          );
        }

        final email = query.docs.first['email'];
        print("Email encontrado para username '$usernameOrEmail': $email");

        // Segundo intento de login con email encontrado
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print(
          "Login exitoso con email derivado del username. UID: ${result.user!.uid}",
        );
        return result.user;
      }

      print("Error no manejado: ${e.code} - ${e.message}");
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

  // En tu archivo auth_service.dart, añade este método:
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print(
        "Error al enviar email de restablecimiento: ${e.code} - ${e.message}",
      );
      rethrow; // Esto permite manejar el error en la UI
    }
  }
}
