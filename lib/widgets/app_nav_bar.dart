import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gazprof/widgets/nav_bar_clipper.dart';

class AppNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int index) onTab;
  final Color navBarBg;
  final Color navIconUnselected;
  final Color brandBlue;

  const AppNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTab,
    required this.navBarBg,
    required this.navIconUnselected,
    required this.brandBlue,
  });

  static const List<Map<String, dynamic>> navItems = [
    {'path': 'assets/home.svg', 'inactiveSize': 24.0, 'activeSize': 22.0},
    {'path': 'assets/file.svg', 'inactiveSize': 29.0, 'activeSize': 22.0},
    {'path': 'assets/time.svg', 'inactiveSize': 33.0, 'activeSize': 24.0},
    {'path': 'assets/user.svg', 'inactiveSize': 24.5, 'activeSize': 22.0},
  ];

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width - 36;
    final tabWidth = screenWidth / 4;
    const double btnSize = 52.0;
    final btnLeft = (tabWidth * selectedIndex) + (tabWidth / 2) - (btnSize / 2);
    const double btnBottom = 12.0;

    return Positioned(
      bottom: 5 + bottomSafePadding,
      left: 18, right: 18,
      child: SizedBox(
        height: 72,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipPath(
              clipper: NavBarClipper(buttonLeft: btnLeft, buttonBottom: btnBottom, buttonSize: btnSize, margin: 4.0),
              child: Container(
                height: 56,
                decoration: BoxDecoration(color: navBarBg, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: List.generate(4, (index) {
                    if (index == selectedIndex) return const Expanded(child: SizedBox());
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTab(index),
                        child: Center(
                          child: SvgPicture.asset(
                            navItems[index]['path'],
                            width: navItems[index]['inactiveSize'],
                            height: navItems[index]['inactiveSize'],
                            colorFilter: ColorFilter.mode(navIconUnselected, BlendMode.srcIn),
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
                decoration: BoxDecoration(color: brandBlue, shape: BoxShape.circle),
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
      ),
    );
  }
}
