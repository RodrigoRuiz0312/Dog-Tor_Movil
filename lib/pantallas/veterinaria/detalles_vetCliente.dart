import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:login/widgets/appbar_diseño.dart';

class ClinicDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> clinica;

  const ClinicDetailsScreen({super.key, required this.clinica});

  // Orden semanal de días
  static const List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  // Función para formatear los horarios en orden semanal
  Widget _buildHorariosWidget(dynamic horariosData) {
    if (horariosData == null) {
      return const Text(
        'Horario no especificado',
        style: TextStyle(fontSize: 15),
      );
    }

    // Si viene como string, intentamos parsearlo a Map
    if (horariosData is String) {
      try {
        final decoded = jsonDecode(horariosData);
        if (decoded is Map) {
          horariosData = decoded;
        } else {
          return Text(horariosData, style: const TextStyle(fontSize: 15));
        }
      } catch (e) {
        return Text(horariosData, style: const TextStyle(fontSize: 15));
      }
    }

    if (horariosData is Map) {
      final List<Widget> horariosWidgets = [];

      for (final dia in _diasSemana) {
        final hora = horariosData[dia]?.toString() ?? 'Cerrado';
        horariosWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    '$dia:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(hora, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: horariosWidgets,
      );
    }

    // Fallback
    return Text(horariosData.toString(), style: const TextStyle(fontSize: 15));
  }

  // Widget para mostrar lista de servicios formateados
  Widget _buildServiciosWidget(List<dynamic> servicios) {
    if (servicios.isEmpty) {
      return const Text(
        'No hay servicios disponibles',
        style: TextStyle(fontSize: 15),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Servicios',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...servicios.map(
          (servicio) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.check, size: 18, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    servicio.toString(),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String _getSafeString(String key) {
      final value = clinica[key];
      if (value == null) return 'No especificado';
      if (value is String) return value;
      return value.toString();
    }

    final nombre = _getSafeString('nombre');
    final direccion = _getSafeString('direccion');
    final telefono = _getSafeString('telefono');
    final imagenUrl = clinica['imagenUrl'] as String?;
    final List<dynamic> servicios = clinica['servicios'] ?? [];

    return Scaffold(
      appBar: buildCustomAppBar(context, 'Detalles $nombre'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagenUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imagenUrl,
                    width: 250,
                    height: 180,
                    fit: BoxFit.cover,
                    placeholder:
                        (_, __) => const SizedBox(
                          width: 250,
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _buildInfoSection('Dirección', direccion),
            _buildInfoSection('Teléfono', telefono),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Horarios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildHorariosWidget(clinica['horarios']),
                  const Divider(height: 20),
                ],
              ),
            ),
            _buildServiciosWidget(servicios),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15)),
        const Divider(height: 20),
      ],
    ),
  );
}
