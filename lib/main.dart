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
    final theme = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // Aici schimbi între LoginScreen(), RegisterScreen() etc.
        body: const LoginScreen(),

        // Butonul care va pluti deasupra oricărui ecran
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.brandBlue,
          onPressed: () => theme.toggleTheme(),
          child: Icon(
            theme.isDark ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}