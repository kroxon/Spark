import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import do Firebase
import 'firebase_options.dart'; // Import pliku konfiguracyjnego

void main() async { // Zmieniamy funkcję na 'async'
  // Upewniamy się, że Flutter jest gotowy
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicjujemy Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iskra',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Iskra połączona z Firebase!'),
        ),
      ),
    );
  }
}