import 'package:flutter/material.dart';
import 'package:gazprof/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added dotenv import

// --- PROVIDERS ---
import 'package:gazprof/core/theme_provider.dart';
import 'package:gazprof/core/user_provider.dart';

void main() async {
  // 1. Getting Flutter ready to run native code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load environment variables securely from .env file
  await dotenv.load(fileName: ".env");

  // 3. Connection with firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Using MultiProvider to manage theme & user's data
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
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
      title: 'GazProf',
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: const LoginScreen(),

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