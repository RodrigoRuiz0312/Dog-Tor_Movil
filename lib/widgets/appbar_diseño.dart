import 'package:flutter/material.dart';

PreferredSizeWidget buildCustomAppBar(BuildContext context, String titleText) {
  return AppBar(
    toolbarHeight: 80,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 0, 234, 255),
            Color.fromARGB(255, 0, 255, 94),
          ],
        ),
      ),
    ),
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white,
        size: 35,
        shadows: [
          Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1)),
        ],
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      titleText,
      style: const TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(blurRadius: 5, color: Colors.black, offset: Offset(1, 1)),
        ],
      ),
    ),
  );
}
