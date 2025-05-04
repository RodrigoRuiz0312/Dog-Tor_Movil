import 'package:flutter/material.dart';

class TitleBanner extends StatelessWidget {
  const TitleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Positioned(
          top: 65,
          left: (width - 200) / 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2195F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'BIENVENIDO A',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: 130,
          left: (width - 285) / 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF2195F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Pet Assist',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                letterSpacing: 7.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: height * 0.23,
          left: (width - 240) / 2,
          child: Image.asset(
            'assets/pluto.png',
            width: 270,
            height: 270,
          ),
        ),
      ],
    );
  }
}
