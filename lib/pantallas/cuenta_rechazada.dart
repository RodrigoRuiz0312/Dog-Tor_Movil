import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CuentaRechazadaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 60, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Cuenta no aprobada',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Lo sentimos, tu solicitud para realizar tu cuenta de veterinario ha sido rechazada. Por favor, contacta al administrador para más información.',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
