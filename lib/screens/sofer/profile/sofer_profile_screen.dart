import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- SERVICES ---
import 'package:gazprof/services/auth_service.dart';

// --- WIDGETS ---
import 'package:gazprof/widgets/app_nav_bar.dart';

// --- SCREENS ---
import '../home/sofer_home_screen.dart';
import '../documente/sofer_documente_screen.dart';
import '../istoric/sofer_istoric_screen.dart';
import 'sofer_personal_data_screen.dart';
import 'sofer_password_set_confirmation_screen.dart';
import 'package:gazprof/auth/login_screen.dart';

class SoferProfileScreen extends StatelessWidget {
  const SoferProfileScreen({super.key});

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
                                MaterialPageRoute(builder: (context) => const SoferPersonalDataScreen()),
                              );
                            },
                          ),
                          Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 55, endIndent: 15),
                          _buildTile('assets/password.svg', 'Schimbă parola', 'Actualizează securitatea', theme, theme.iconLock, theme.bgLock, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SoferPasswordConfirmScreen(email: userProvider.userEmail)),
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

                        // DISCONNECT
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
                        Text(
                          "Versiune 1.0.1.2",
                          style: TextStyle(color: theme.textSecondary, fontSize: 10),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // NAVBAR
          AppNavBar(
            selectedIndex: 3,
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
              role,
              style: TextStyle(color: theme.roleSofer, fontSize: 12)
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

  void _showNavigationPicker(BuildContext context, ThemeProvider theme, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Alege navigația implicită", 
                  style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildOptionTile(context, "Google Maps", theme, userProvider),
                _buildOptionTile(context, "Waze", theme, userProvider),
                const SizedBox(height: 10),
              ],
            ),
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
    if (index == 0) {
      nextScreen = const SoferHomeScreen();
    } else if (index == 1) {
      nextScreen = const SoferDocumenteScreen();
    } else if (index == 2) {
      nextScreen = const SoferIstoricScreen();
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

