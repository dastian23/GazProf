import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

void main() {
  runApp(const GazProfApp());
}

class GazProfApp extends StatelessWidget {
  const GazProfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GazProf',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const LoginScreen(),
    );
  }
}