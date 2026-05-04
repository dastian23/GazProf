import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 140),
              child: Column(
                children: [
                  // --- HEADER BOX ---
                  _buildHeader(theme),

                  const SizedBox(height: 10),

                  // --- CONT SECTION ---
                  _buildSectionLabel('CONT', theme),
                  _buildProfileCard(theme, [
                    _buildTile('assets/user.svg', 'Date personale', 'Nume, telefon, email', theme, theme.iconPerson, theme.bgPerson),
                    const Divider(color: Colors.black12, height: 1, indent: 60, endIndent: 20),
                    _buildTile('assets/password.svg', 'Schimbă parola', 'Actualizează securitatea', theme, theme.iconLock, theme.bgLock),
                  ]),

                  // --- PREFERINTE SECTION ---
                  _buildSectionLabel('PREFERINȚE', theme),
                  _buildProfileCard(theme, [
                    _buildTile('assets/harta.svg', 'Navigație implicită', 'Waze', theme, theme.iconMaps, theme.bgMaps),
                    const Divider(color: Colors.black12, height: 1, indent: 60, endIndent: 20),
                    _buildThemeTile(theme),
                  ]),

                  const SizedBox(height: 20),

                  // --- DECONNECTING SECTION ---
                  _buildProfileCard(theme, [
                    ListTile(
                      leading: _buildIcon('assets/deconnect.svg', theme.iconLogout, theme.bgLogout),
                      title: const Center(
                          child: Text(
                              'Deconectare',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
                          )
                      ),
                      trailing: const SizedBox(width: 40),
                      onTap: () {
                        // Logică logout
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // --- NAV BAR WITH A SVG CUT  ---
          Positioned(
            bottom: 25,
            left: 18,
            right: 18,
            child: _buildCustomNavBar(theme),
          ),
        ],
      ),
    );
  }

  // --- WIDGET FOR NAVBAR ---
  Widget _buildCustomNavBar(ThemeProvider theme) {
    return SizedBox(
      height: 90,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. THE BASE ( RECTANGLE )
          Container(
            height: 69,
            decoration: BoxDecoration(
              color: theme.navBarBg,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(child: Center(child: _buildNavIcon('assets/home.svg', 30, 33, theme))),
                Expanded(child: Center(child: _buildNavIcon('assets/file.svg', 25, 35, theme))),
                Expanded(child: Center(child: _buildNavIcon('assets/time.svg', 43, 43, theme))),
                const SizedBox(width: 95),
              ],
            ),
          ),

          // 2. SVG "CUT" ( FOR SIMULATING THAT CUTTING IN THE BASE )
          Positioned(
            right: 1,
            bottom: 12,
            child: SvgPicture.asset(
              'assets/cut.svg',
              width: 110,
              colorFilter: ColorFilter.mode(theme.scaffoldBg, BlendMode.srcIn),
            ),
          ),

          // 3. PROFILE BUTON
          Positioned(
            right: 24,
            bottom: 15,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0779B7),
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBg, width: 3),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/user.svg',
                  width: 30,
                  height: 34,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildHeader(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: theme.headerBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: theme.brandBlue,
            child: const Text('IM', style: TextStyle(fontSize: 38, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          Text('Ion Munteanu', style: TextStyle(color: theme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Șofer', style: TextStyle(color: theme.textGriFix, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, bottom: 8, top: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
            text,
            style: TextStyle(color: theme.sectionLabel, fontSize: 18, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeProvider theme, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.cardOutline, width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(String svgPath, String title, String sub, ThemeProvider theme, Color iColor, Color bColor) {
    return ListTile(
      leading: _buildIcon(svgPath, iColor, bColor),
      title: Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(sub, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: theme.textGriFix, size: 20),
      onTap: () {},
    );
  }

  Widget _buildThemeTile(ThemeProvider theme) {
    return ListTile(
      leading: _buildIcon('assets/theme.svg', theme.iconMaps, theme.bgMaps),
      title: Text('Temă', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text('Luminoasă, întunecată', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
      trailing: CupertinoSwitch(
        activeTrackColor: theme.brandBlue,
        value: theme.isDark,
        onChanged: (v) => theme.toggleTheme(),
      ),
    );
  }

  Widget _buildIcon(String svgPath, Color iColor, Color bColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bColor, borderRadius: BorderRadius.circular(10)),
      child: SvgPicture.asset(
          svgPath,
          colorFilter: ColorFilter.mode(iColor, BlendMode.srcIn),
          width: 22,
          height: 22,
      ),
    );
  }

  Widget _buildNavIcon(String path, double w, double h, ThemeProvider theme) {
    return SvgPicture.asset(
      path,
      width: w,
      height: h,
      colorFilter:ColorFilter.mode(theme.navIconUnselected, BlendMode.srcIn),
    );
  }
}