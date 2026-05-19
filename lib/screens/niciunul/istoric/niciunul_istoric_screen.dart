import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- WIDGETS ---
import 'package:gazprof/widgets/app_nav_bar.dart';
import 'package:gazprof/widgets/profile_avatar.dart';

// --- SCREENS ---
import '../home/niciunul_home_screen.dart';
import '../documente/niciunul_documente_screen.dart';
import '../profile/niciunul_profile_screen.dart';

class NiciunulIstoricScreen extends StatelessWidget {
  const NiciunulIstoricScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // TOP HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/logo_gazprof.png', height: 20),
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: ProfileAvatar(name: userProvider.userName, color: theme.brandBlue),
                      ),
                    ],
                  ),
                ),

                //  WELCOME BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bun venit,", style: TextStyle(color: theme.textGriFix, fontSize: 13)),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: userProvider.userName),
                            const TextSpan(text: " - ", style: TextStyle(fontWeight: FontWeight.normal)),
                            TextSpan(
                              text: userProvider.userRole,
                              style: TextStyle(color: theme.roleNeatribuit, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                    ],
                  ),
                ),

                // CENTRAL CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: theme.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F0),
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.isDark ? Colors.white10 : Colors.black12),
                          ),
                          child: Icon(Icons.lock_outline, size: 30, color: theme.textSecondary),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "Acces restricționat",
                          style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "Nu ai acces la această secțiune.\nAșteaptă atribuirea unui rol\nde către administrator.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.textGriFix, fontSize: 13, height: 1.4),
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // NAVBAR
          AppNavBar(
            selectedIndex: 2,
            onTab: (i) => _navigate(context, i),
            navBarBg: theme.navBarBg,
            navIconUnselected: theme.navIconUnselected,
            brandBlue: theme.brandBlue,
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  void _navigate(BuildContext context, int index) {
    if (index == 2) return;

    Widget nextScreen;
    if (index == 0) {
      nextScreen = const NiciunulHomeScreen();
    } else if (index == 1) {
      nextScreen = const NiciunulDocumenteScreen();
    } else {
      nextScreen = const NiciunulProfileScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => nextScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

