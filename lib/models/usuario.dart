import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String email;
  final String username;
  final String nombre;
  final String apellidos;
  final String tipoUsuario; // 'cliente', 'veterinario', 'admin'
  final DateTime createdAt;

  Usuario({
    required this.uid,
    required this.email,
    required this.username,
    required this.nombre,
    required this.apellidos,
    required this.tipoUsuario,
    required this.createdAt,
  });

  Usuario copyWith({
    String? uid,
    String? email,
    String? username,
    String? nombre,
    String? apellidos,
    String? tipoUsuario,
    DateTime? createdAt,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Usuario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Usuario(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      nombre: data['nombre'] ?? '',
      apellidos: data['apellidos'] ?? '',
      tipoUsuario: data['tipoUsuario'] ?? 'cliente',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'nombre': nombre,
      'apellidos': apellidos,
      'tipoUsuario': tipoUsuario,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  bool get esVeterinario => tipoUsuario == 'veterinario';
  bool get esAdmin => tipoUsuario == 'admin';
}
