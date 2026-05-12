import 'package:flutter/material.dart';
import 'package:gazprof/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 adăugat
import 'package:cloud_firestore/cloud_firestore.dart';
// --- PROVIDERS ---
import 'package:gazprof/core/theme_provider.dart';
import 'package:gazprof/core/user_provider.dart';

// 👇 importă ecranul principal (înlocuiește cu calea corectă)
import 'package:gazprof/screens/niciunul/home/niciunul_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        body: const AuthWrapper(), // 👈 înlocuit LoginScreen cu AuthWrapper
      ),
    );
  }
}

// ─────────────────────────────────────────────
// AuthWrapper — ascultă starea autentificării
// ─────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
         
        // 1. Se încarcă
        if (snapshot.connectionState == ConnectionState.waiting) {
          final theme = Provider.of<ThemeProvider>(context, listen: false);
          return Scaffold(
            backgroundColor: theme.scaffoldBg, // același fundal ca restul aplicației
          );
        }

        // 2. Utilizator autentificat — citește rolul din Firestore
        if (snapshot.hasData && snapshot.data != null) {
          return const RoleRouter(); // 👈 widget nou
        }

        // 3. Neautentificat
        return const LoginScreen();
      },
    );
  }
}

// ─────────────────────────────────────────────
// RoleRouter — citește rolul și redirecționează
// ─────────────────────────────────────────────
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          final theme = Provider.of<ThemeProvider>(context, listen: false);
          return Scaffold(
            backgroundColor: theme.scaffoldBg,
            body: Center(
              child: Image.asset('assets/app_icon.png', height: 100),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const LoginScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String rol = data['rol'] ?? '';
        final String nume = data['nume'] ?? '';
        final String status = data['status'] ?? 'neatribuit';

        // Salvează în Provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<UserProvider>(context, listen: false).setUserData(nume, status);
        });

        // Redirecționează după rol
        if (rol == 'niciunul') {
          return const NiciunulHomeScreen();
        } else {
          // Alte roluri în lucru — deloghez și trimit la Login
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }
      },
    );
  }
}