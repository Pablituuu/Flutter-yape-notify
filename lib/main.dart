import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const YapeNotificacionesApp());
}

class YapeNotificacionesApp extends StatelessWidget {
  const YapeNotificacionesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yape Pablituuu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111A), // Color oscuro tipo navy
        primaryColor: const Color(0xFF7A4EE5), // Morado yape aproximado
        useMaterial3: true,
        fontFamily: 'Roboto', // Fuente genérica por defecto clara
      ),
      home: const HomeScreen(),
    );
  }
}
