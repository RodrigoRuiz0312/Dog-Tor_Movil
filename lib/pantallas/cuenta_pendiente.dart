import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CuentaPendienteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 60, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Cuenta en revisión',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Tu cuenta de veterinario está pendiente de aprobación por un administrador.',
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
