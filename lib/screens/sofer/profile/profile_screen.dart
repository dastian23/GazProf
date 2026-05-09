import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

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
                // 1. HEADER - Mai compact pentru a câștiga spațiu jos
                _buildHeader(theme),

                // 2. CONȚINUT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 5), // Spațiu minim sus

                        _buildSectionLabel('CONT', theme),
                        _buildProfileCard(theme, [
                          _buildTile('assets/user.svg', 'Date personale', 'Nume, telefon, email', theme, theme.iconPerson, theme.bgPerson),
                          Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 55, endIndent: 15),
                          _buildTile('assets/password.svg', 'Schimbă parola', 'Actualizează securitatea', theme, theme.iconLock, theme.bgLock),
                        ]),

                        const SizedBox(height: 5), // Redus pentru a ridica secțiunea următoare

                        _buildSectionLabel('PREFERINȚE', theme),
                        _buildProfileCard(theme, [
                          _buildTile('assets/harta.svg', 'Navigație implicită', 'Waze', theme, theme.iconMaps, theme.bgMaps),
                          Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 55, endIndent: 15),
                          _buildThemeTile(theme),
                        ]),

                        const SizedBox(height: 10), // Spațiu controlat înainte de Deconectare

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
                            onTap: () {},
                          ),
                        ]),

                        // Acest Spacer va asigura că butonul de deconectare nu se lipește de Navbar
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // NAVBAR
          Positioned(
            bottom: 22,
            left: 18,
            right: 18,
            child: _buildCustomNavBar(theme),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS AJUSTATE ---

  Widget _buildHeader(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18), // Redus de la 20
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
            radius: 38, // Redus de la 42 pentru a câștiga spațiu vertical
            backgroundColor: theme.brandBlue,
            child: const Text('IM', style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text('Ion Munteanu', style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Șofer', style: TextStyle(color: theme.textGriFix, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4, top: 10), // Padding redus
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
            text,
            style: TextStyle(color: theme.sectionLabel, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeProvider theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(15), // Radius ușor mai mic
        border: Border.all(color: theme.cardOutline, width: 1.0),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(String svgPath, String title, String sub, ThemeProvider theme, Color iColor, Color bColor) {
    return ListTile(
      dense: true,
      leading: _buildIcon(svgPath, iColor, bColor),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(sub, style: TextStyle(color: theme.textSecondary, fontSize: 11)),
      trailing: Icon(Icons.chevron_right, color: theme.textGriFix, size: 18),
      onTap: () {},
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
      padding: const EdgeInsets.all(7), // Redus de la 8
      decoration: BoxDecoration(color: bColor, borderRadius: BorderRadius.circular(8)),
      child: SvgPicture.asset(
        svgPath,
        colorFilter: ColorFilter.mode(iColor, BlendMode.srcIn),
        width: 17, // Redus de la 18
        height: 17,
      ),
    );
  }

  // --- NAVBAR ---
  Widget _buildCustomNavBar(ThemeProvider theme) {
    return SizedBox(
      height: 72, // Redus de la 75
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: theme.navBarBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(child: Center(child: _buildNavIcon('assets/home.svg', 23, theme))),
                Expanded(child: Center(child: _buildNavIcon('assets/file.svg', 24, theme))),
                Expanded(child: Center(child: _buildNavIcon('assets/time.svg', 29, theme))),
                const SizedBox(width: 80),
              ],
            ),
          ),
          Positioned(
            right: -2,
            bottom: 8,
            child: SvgPicture.asset(
              'assets/cut.svg',
              width: 95,
              colorFilter: ColorFilter.mode(theme.scaffoldBg, BlendMode.srcIn),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 12,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.brandBlue,
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBg, width: 3),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/user.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(String path, double size, ThemeProvider theme) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(theme.navIconUnselected, BlendMode.srcIn),
    );
  }
}