import 'package:cloud_firestore/cloud_firestore.dart';

class Veterinario {
  final String uid;
  final String cedulaProfesional;
  final String especialidad;
  final String? veterinariaId;
  final String estado; // 'pendiente', 'aprobado', 'rechazado'

  Veterinario({
    required this.uid,
    required this.cedulaProfesional,
    required this.especialidad,
    this.veterinariaId,
    this.estado = 'pendiente',
  });

  factory Veterinario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Veterinario(
      uid: doc.id,
      cedulaProfesional: data['cedulaProfesional'],
      especialidad: data['especialidad'],
      veterinariaId: data['veterinariaId'],
      estado: data['estado'] ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cedulaProfesional': cedulaProfesional,
      'especialidad': especialidad,
      if (veterinariaId != null) 'veterinariaId': veterinariaId,
      'estado': estado,
    };
  }
}