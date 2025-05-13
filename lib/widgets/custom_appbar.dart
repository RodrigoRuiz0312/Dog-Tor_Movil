import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:lottie/lottie.dart';
import '../pantallas/perfil_cliente.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User user;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onLogoutPressed;

  const CustomAppBar({
    super.key,
    required this.user,
    required this.scaffoldKey,
    this.onProfilePressed,
    this.onLogoutPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  void _defaultProfileAction(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Lottie.asset(
              'assets/animaciones/loading_animation.json',
              width: 150,
              height: 150,
            ),
          ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PerfilClienteScreen(user: user),
        ),
      );
    }
  }

  void _defaultLogoutAction(BuildContext context) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      desc: '¿Desea cerrar sesión?',
      btnCancelText: 'Cancelar',
      btnOkText: 'Cerrar Sesión',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
      descTextStyle: const TextStyle(fontSize: 30),
      buttonsBorderRadius: BorderRadius.circular(10),
      dismissOnTouchOutside: false,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(Icons.menu_sharp, color: Colors.white, size: 40),
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
        ),
      ],
      title: const Padding(
        padding: EdgeInsets.symmetric(vertical: 50),
        child: Text(
          'Dog-Tor',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFamily: 'Short',
            letterSpacing: 7.0,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      ),
      // Eliminamos los actions ya que estarán en el Drawer
    );
  }
}
