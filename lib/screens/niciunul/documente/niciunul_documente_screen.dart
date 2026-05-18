import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- SCREENS ---
import '../profile/niciunul_profile_screen.dart';
import '../istoric/niciunul_istoric_screen.dart';
import '../home/niciunul_home_screen.dart';

class NiciunulDocumenteScreen extends StatelessWidget {
  const NiciunulDocumenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;


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
                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/logo_gazprof.png', height: 20),
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: _buildProfileCircle(userProvider.userName, theme),
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
          Positioned(bottom: 5 + bottomSafePadding,
              left: 18,
              right: 18,
              child: _buildCustomNavBar(context, theme, 1)),
        ],
      ),
    );
  }

  Widget _buildProfileCircle(String name, ThemeProvider theme) {
    String initials = "U";
    if (name.isNotEmpty) {
      List<String> words = name.trim().split(RegExp(r'\s+'));
      initials = words.length > 1 ? (words[0][0] + words[1][0]).toUpperCase() : words[0][0].toUpperCase();
    }
    return Container(
      width: 35, height: 35,
      decoration: BoxDecoration(color: theme.brandBlue, shape: BoxShape.circle),
      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildCustomNavBar(BuildContext context, ThemeProvider theme, int selectedIndex) {
    double screenWidth = MediaQuery.of(context).size.width - 36;
    double tabWidth = screenWidth / 4;
    const double btnSize = 52.0;
    double btnLeft = (tabWidth * selectedIndex) + (tabWidth / 2) - (btnSize / 2);
    const double btnBottom = 12.0;

    // Added active/inactive sizes to prevent icon distortion
    List<Map<String, dynamic>> navItems = [
      {'path': 'assets/home.svg', 'inactiveSize': 24.0, 'activeSize': 22.0},
      {'path': 'assets/file.svg', 'inactiveSize': 29.0, 'activeSize': 22.0},
      {'path': 'assets/time.svg', 'inactiveSize': 33.0, 'activeSize': 24.0},
      {'path': 'assets/user.svg', 'inactiveSize': 24.5, 'activeSize': 22.0},
    ];

    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipPath(
            clipper: _NavBarClipper(buttonLeft: btnLeft, buttonBottom: btnBottom, buttonSize: btnSize, margin: 4.0),
            child: Container(
              height: 56,
              decoration: BoxDecoration(color: theme.navBarBg, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: List.generate(4, (index) {
                  if (index == selectedIndex) return const Expanded(child: SizedBox());
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _navigate(context, index),
                      child: Center(
                        child: SvgPicture.asset(
                          navItems[index]['path'],
                          width: navItems[index]['inactiveSize'], // Use inactive size here
                          height: navItems[index]['inactiveSize'],
                          colorFilter: ColorFilter.mode(theme.navIconUnselected, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            left: btnLeft, bottom: btnBottom,
            child: Container(
              width: btnSize, height: btnSize,
              decoration: BoxDecoration(color: theme.brandBlue, shape: BoxShape.circle),
              child: Center(
                  child: SvgPicture.asset(
                      navItems[selectedIndex]['path'],
                      width: navItems[selectedIndex]['activeSize'], // Use active size here
                      height: navItems[selectedIndex]['activeSize'],
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  )
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == 1) return;

    Widget nextScreen;
    if (index == 0) {
      nextScreen = const NiciunulHomeScreen();
    } else if (index == 2) {
      nextScreen = const NiciunulIstoricScreen();
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

class _NavBarClipper extends CustomClipper<Path> {
  final double buttonLeft;
  final double buttonBottom;
  final double buttonSize;
  final double margin;

  _NavBarClipper({required this.buttonLeft, required this.buttonBottom, required this.buttonSize, required this.margin});

  @override
  Path getClip(Size size) {
    Path barPath = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(24)));
    double centerX = buttonLeft + (buttonSize / 2);
    double centerY = size.height - (buttonBottom + (buttonSize / 2));
    Path holePath = Path()..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: (buttonSize / 2) + margin));
    return Path.combine(PathOperation.difference, barPath, holePath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}