import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hebrew Voice Assistant',
      home: HomeScreen(), // <--- This is critical!
      debugShowCheckedModeBanner: false,
    );
  }
}