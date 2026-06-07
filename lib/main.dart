import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- PROVIDERS & SERVICES ---
import 'package:gazprof/core/theme_provider.dart';
import 'package:gazprof/core/user_provider.dart';
import 'package:gazprof/services/notification_service.dart';
import 'package:gazprof/services/fcm_service.dart';
import 'package:flutter/services.dart';

// --- SCREENS ---
import 'package:gazprof/auth/login_screen.dart';
import 'package:gazprof/screens/niciunul/home/niciunul_home_screen.dart';
import 'package:gazprof/screens/sofer/home/sofer_home_screen.dart';
import 'package:gazprof/screens/dispecer/home/dispecer_home_screen.dart';
import 'package:gazprof/screens/admin/home/admin_home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final role = doc['rol']?.toString().toLowerCase() ?? '';
        if (role == 'sofer') {
          NotificationService().startOrderListener();
        }
      }
    } catch (_) {}
  });

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
      navigatorKey: navigatorKey,
      themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
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
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
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
          return const SoferHomeScreen();
        } else if (rol == 'dispecer') {
          return const DispecerHomeScreen();
        } else if (rol == 'admin' || rol == 'administrator') {
          return const AdminHomeScreen();
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