import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gazprof/screens/dispecer/home/dispecer_home_screen.dart';
import 'package:gazprof/screens/niciunul/profile/niciunul_password_set_confirmation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gazprof/services/auth_service.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';
import 'package:provider/provider.dart';


// --- SCREENS ---
import 'package:gazprof/screens/dispecer/profile/dispecer_personal_data_screen.dart';
import 'package:gazprof/auth/login_screen.dart';

class DispecerProfileScreen extends StatelessWidget {
  const DispecerProfileScreen({super.key});

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
                _buildHeader(theme, userProvider.userName, userProvider.userRole),

                // PROFILE CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),

                        _buildSectionLabel('CONT', theme),
                        _buildProfileCard(theme, [
                          _buildTile(
                            'assets/user.svg',
                            'Date personale',
                            'Nume, telefon, email',
                            theme,
                            theme.iconPerson,
                            theme.bgPerson,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DispecerPersonalDataScreen()),
                              );
                            },
                          ),
                          Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 55, endIndent: 15),
                          _buildTile('assets/password.svg', 'Schimbă parola', 'Actualizează securitatea', theme, theme.iconLock, theme.bgLock, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChangePasswordConfirmScreen(email: userProvider.userEmail)),
                            );
                          }),
                        ]),

                        const SizedBox(height: 5),

                        _buildSectionLabel('PREFERINȚE', theme),
                        _buildProfileCard(theme, [
                          _buildTile('assets/harta.svg', 'Navigație implicită', userProvider.navigationApp, theme, theme.iconMaps, theme.bgMaps, onTap: () => _showNavigationPicker(context, theme, userProvider),
                          ),
                          Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 55, endIndent: 15),
                          _buildThemeTile(theme),
                        ]),

                        const SizedBox(height: 10),

                        // DECONECTARE
                        _buildProfileCard(theme, [
                          ListTile(
                            dense: true,
                            leading: _buildIcon('assets/deconnect.svg', theme.iconLogout, theme.bgLogout),
                            title: const Center(
                                child: Text(
                                    'Deconectare',
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)
                                )
                            ),
                            trailing: const SizedBox(width: 40),
                            onTap: () async {
                              await AuthService().logOut();

                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear();

                              if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                      (route) => false,
                                );
                              }
                            },
                          ),
                        ]),

                        const Spacer(flex: 1),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // NAVBAR
          Positioned(
            bottom: 5 + bottomSafePadding,
            left: 18,
            right: 18,
            child: _buildCustomNavBar(context, theme, 3),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildHeader(ThemeProvider theme, String name, String role) {
    String initials = "U";
    if (name.isNotEmpty) {
      List<String> words = name.trim().split(RegExp(r'\s+'));
      initials = words.length > 1 ? (words[0][0] + words[1][0]).toUpperCase() : words[0][0].toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: theme.headerBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: theme.brandBlue,
            child: Text(initials, style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
              role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : '',
              style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 12)
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4, top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: TextStyle(color: theme.sectionLabel, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }

  Widget _buildProfileCard(ThemeProvider theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.cardOutline, width: 1.0),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(String svgPath, String title, String sub, ThemeProvider theme, Color iColor, Color bColor, {VoidCallback? onTap}) {
    return ListTile(
      dense: true,
      leading: _buildIcon(svgPath, iColor, bColor),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(sub, style: TextStyle(color: theme.textSecondary, fontSize: 11)),
      trailing: Icon(Icons.chevron_right, color: theme.textGriFix, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildThemeTile(ThemeProvider theme) {
    return ListTile(
      dense: true,
      leading: _buildIcon('assets/theme.svg', theme.iconMaps, theme.bgMaps),
      title: Text('Temă', style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(theme.isDark ? 'Întunecată' : 'Luminoasă', style: TextStyle(color: theme.textSecondary, fontSize: 11)),
      trailing: Transform.scale(
        scale: 0.7,
        child: CupertinoSwitch(
          activeTrackColor: theme.brandBlue,
          value: theme.isDark,
          onChanged: (v) => theme.toggleTheme(),
        ),
      ),
    );
  }

  Widget _buildIcon(String svgPath, Color iColor, Color bColor) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: bColor, borderRadius: BorderRadius.circular(8)),
      child: SvgPicture.asset(svgPath, colorFilter: ColorFilter.mode(iColor, BlendMode.srcIn), width: 17, height: 17),
    );
  }

  // --- NAVBAR & ROUTING ---

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
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showNavigationPicker(BuildContext context, ThemeProvider theme, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Alege navigația implicită",
                  style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              _buildOptionTile(context, "Google Maps", theme, userProvider),
              _buildOptionTile(context, "Waze", theme, userProvider),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(BuildContext context, String name, ThemeProvider theme, UserProvider provider) {
    bool isSelected = provider.navigationApp == name;
    return ListTile(
      title: Text(name, style: TextStyle(color: theme.textPrimary)),
      trailing: isSelected ? Icon(Icons.check_circle, color: theme.brandBlue) : null,
      onTap: () {
        provider.setNavigationApp(name);
        Navigator.pop(context);
      },
    );
  }


  void _navigate(BuildContext context, int index) {
    if (index == 3) return;

    Widget nextScreen;
    // Removed constructor parameters for clean navigation
    if (index == 0) {
      nextScreen = const DispecerHomeScreen();
    } else if (index == 1) {
      nextScreen = const Center(child: Text("Ecran Documente"));
    } else if (index == 2) {
      nextScreen = const Center(child: Text("Ecran Istoric"));
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