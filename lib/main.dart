import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gazprof/core/constants.dart';

// --- PROVIDERS & SERVICES ---
import 'package:gazprof/core/theme_provider.dart';
import 'package:gazprof/core/user_provider.dart';
import 'package:gazprof/core/products_provider.dart';
import 'package:gazprof/services/notification_service.dart';
import 'package:gazprof/services/fcm_service.dart';
import 'package:flutter/services.dart';

// --- SCREENS ---
import 'package:gazprof/auth/login_screen.dart';
import 'package:gazprof/screens/niciunul/home/niciunul_home_screen.dart';
import 'package:gazprof/screens/sofer/sofer_shell.dart';
import 'package:gazprof/screens/dispecer/dispecer_shell.dart';
import 'package:gazprof/screens/admin/admin_shell.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Notification services
  await NotificationService().initialize();
  await FcmService().initialize();

  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user == null) {
      NotificationService().stopOrderListener();
      return;
    }

    try {
      await NotificationService().saveFcmTokenIfNeeded();
      final doc = await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(user.uid).get();
      if (doc.exists) {
        final role = doc['rol']?.toString().toLowerCase() ?? '';
        if (role == 'sofer') {
          NotificationService().startOrderListener();
        }
      }
    } catch (e) {
      debugPrint("Eroare authStateChanges: $e");
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
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
      navigatorKey: navigatorKey,
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        canvasColor: const Color(0xFFF7F7F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0779B7),
          surface: Color(0xFFF7F7F7),
          onSurface: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0779B7),
          surface: Colors.black,
          onSurface: Colors.white,
        ),
      ),
      home: Scaffold(
        body: const AuthWrapper(),
      ),
    );
  }
}

// AuthWrapper — listen to authentification state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (!theme.isLoaded) {
      return Scaffold(backgroundColor: Colors.black);
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBg,
          );
        }

        // 2. User authenticated
        if (snapshot.hasData && snapshot.data != null) {
          return const RoleRouter();
        }

        // 3. Not registered
        return const LoginScreen();
      },
    );
  }
}

// RoleRouter — reads the role and redirect to the right screen
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  // Cache the future in initState so it is never recreated on rebuild
  late final Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userFuture = FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
    } else {
      // Provide a never-completing future; AuthWrapper will redirect to login
      _userFuture = Completer<DocumentSnapshot>().future;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          final theme = Provider.of<ThemeProvider>(context, listen: false);

          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: theme.scaffoldBg,
          ));

          return Scaffold(
            backgroundColor: theme.scaffoldBg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/flame.svg',
                    width: 45, height: 65,
                    colorFilter: ColorFilter.mode(theme.brandBlue, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 8),
                  Image.asset('assets/logo_gazprof.png', height: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Gestionare livrări',
                    style: TextStyle(color: theme.textGriFix, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await FirebaseAuth.instance.signOut();
          });
          return const LoginScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String rol = data['rol']?.toString().toLowerCase() ?? 'neatribuit';
        final String nume = data['nume'] ?? '';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<UserProvider>(context, listen: false).setUserData(nume, rol, data['email'] ?? '');
        });

        if (rol == 'neatribuit') {
          return const NiciunulHomeScreen();
        } else if (rol == 'sofer') {
          return const SoferShell();
        } else if (rol == 'dispecer') {
          return const DispecerShell();
        } else if (rol == 'admin' || rol == 'administrator') {
          return const AdminShell();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await FirebaseAuth.instance.signOut();
          });
          return const LoginScreen();
        }
      },
    );
  }
}