import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:gazprof/core/theme_provider.dart';
import 'package:gazprof/widgets/app_nav_bar.dart';

import 'home/sofer_home_screen.dart';
import 'documente/sofer_documente_screen.dart';
import 'istoric/sofer_istoric_screen.dart';
import 'profile/sofer_profile_screen.dart';

class SoferShell extends StatefulWidget {
  const SoferShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<SoferShell> createState() => SoferShellState();
}

class SoferShellState extends State<SoferShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  static SoferShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<SoferShellState>();

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
          IndexedStack(
            index: _currentIndex,
            children: const [
              _KeepAliveTab(child: SoferHomeScreen()),
              _KeepAliveTab(child: SoferDocumenteScreen()),
              _KeepAliveTab(child: SoferIstoricScreen()),
              _KeepAliveTab(child: SoferProfileScreen()),
            ],
          ),
          AppNavBar(
            selectedIndex: _currentIndex,
            onTab: switchTab,
            navBarBg: theme.navBarBg,
            navIconUnselected: theme.navIconUnselected,
            brandBlue: theme.brandBlue,
          ),
        ],
      ),
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});
  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
