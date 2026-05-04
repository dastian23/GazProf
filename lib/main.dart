import 'package:flutter/material.dart';
import 'package:gazprof/auth/login_screen.dart';
import 'package:provider/provider.dart';
// Importurile tale (verifică să fie căile corecte spre folderele tale)
import 'package:gazprof/core/theme_provider.dart';
import 'package:gazprof/screens/sofer/profile/profile_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const GazProfApp(),
    ),
  );
}

class GazProfApp extends StatelessWidget {
  const GazProfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}