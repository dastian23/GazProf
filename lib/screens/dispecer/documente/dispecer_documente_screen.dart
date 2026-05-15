import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gazprof/screens/dispecer/istoric/dispecer_istoric_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- SCREENS ---
import '../home/dispecer_home_screen.dart';
import '../profile/dispecer_profile_screen.dart';

// --- INTERNAL COMPONENTS ---
import 'dispecer_documente_empty.dart';
import 'dispecer_documente_list.dart';

class DispecerDocumenteScreen extends StatefulWidget {
  const DispecerDocumenteScreen({super.key});

  @override
  State<DispecerDocumenteScreen> createState() => _DispecerDocumenteScreenState();
}

class _DispecerDocumenteScreenState extends State<DispecerDocumenteScreen> {

  // -- MODIFY THIS TO TEST ---
  bool _esteInProgram() {
    //final oraCurenta = DateTime.now().hour;
    //return oraCurenta >= 6 && oraCurenta < 18;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    ));

    // --- DEFINING THE TIME RANGE FOR ORDERS  ---
    final now = DateTime.now();
    // Today at start 6,0,0
    final startOfShift = DateTime(now.year, now.month, now.day, 0, 0, 0);
    // Today at end 18, 0, 0
    final endOfShift = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Monitorizare comenzi",
                        style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: _buildProfileCircle(userProvider.userName, theme),
                      ),
                    ],
                  ),
                ),

                // --- DYNAMIC RANGE  ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('comenzi')
                    // 1. Filter to be >= today at hour 06:00
                        .where('data_creare', isGreaterThanOrEqualTo: startOfShift)
                    // 2. Filter to be < today at hour 18:00
                        .where('data_creare', isLessThan: endOfShift)
                    // 3. We order from the new to the oldest
                        .orderBy('data_creare', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: theme.brandBlue));
                      }

                      final comenzi = snapshot.data?.docs ?? [];
                      final inProgram = _esteInProgram();

                      if (!inProgram || comenzi.isEmpty) {
                        return const DispecerDocumenteEmpty();
                      }

                      return DispecerDocumenteList(comenzi: comenzi);
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- NAVBAR ---
          Positioned(
            bottom: 5 + bottomSafePadding,
            left: 18, right: 18,
            child: _buildCustomNavBar(context, theme, 1),
          ),
        ],
      ),
    );
  }

  // --- HELPERS UI  ---
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

  void _navigate(BuildContext context, int index) {
    if (index == 1) return;

    Widget nextScreen;
    if (index == 0) {
      nextScreen = const DispecerHomeScreen();
    } else if (index == 2) {
      nextScreen = const DispecerIstoricScreen();
    } else if (index == 3) {
      nextScreen = const DispecerProfileScreen();
    } else {
      return;
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

  Widget _buildCustomNavBar(BuildContext context, ThemeProvider theme, int selectedIndex) {
    double screenWidth = MediaQuery.of(context).size.width - 36;
    double tabWidth = screenWidth / 4;
    const double btnSize = 52.0;
    double btnLeft = (tabWidth * selectedIndex) + (tabWidth / 2) - (btnSize / 2);
    const double btnBottom = 12.0;

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
                          width: navItems[index]['inactiveSize'],
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
                      width: navItems[selectedIndex]['activeSize'],
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