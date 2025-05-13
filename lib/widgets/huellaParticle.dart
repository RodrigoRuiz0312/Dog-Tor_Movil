import 'dart:math';
import 'package:flutter/material.dart';

class HuellitasParticles extends StatefulWidget {
  final int cantidad;
  final double ancho;
  final double alto;

  const HuellitasParticles({
    super.key,
    this.cantidad = 20,
    required this.ancho,
    required this.alto,
  });

  @override
  State<HuellitasParticles> createState() => _HuellitasParticlesState();
}

class _HuellitasParticlesState extends State<HuellitasParticles>
    with SingleTickerProviderStateMixin {
  late List<_Huella> _huellas;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _huellas = List.generate(widget.cantidad, (_) => _crearHuella());
    _animarHuellas();
  }

  _Huella _crearHuella() {
    return _Huella(
      top: _rng.nextDouble() * widget.alto,
      left: _rng.nextDouble() * widget.ancho,
      size: _rng.nextDouble() * 24 + 16,
      opacity: _rng.nextDouble(),
    );
  }

  void _animarHuellas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _huellas = List.generate(widget.cantidad, (_) => _crearHuella());
      });
      _animarHuellas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.ancho,
      height: widget.alto,
      child: Stack(
        children:
            _huellas
                .map(
                  (huella) => Positioned(
                    top: huella.top,
                    left: huella.left,
                    child: Opacity(
                      opacity: huella.opacity,
                      child: Image.asset(
                        'assets/huellaParticles.png',
                        width: huella.size,
                        height: huella.size,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _Huella {
  final double top;
  final double left;
  final double size;
  final double opacity;

  _Huella({
    required this.top,
    required this.left,
    required this.size,
    required this.opacity,
  });
}
