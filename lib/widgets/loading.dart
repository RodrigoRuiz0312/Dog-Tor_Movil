import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        height: 300,
        width: 300,
        child: Lottie.asset(
          'assets/animaciones/loading_animation_3.json',
        ), // Asegúrate de tener este archivo
      ),
    );
  }
}
