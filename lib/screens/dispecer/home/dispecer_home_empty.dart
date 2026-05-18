import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme_provider.dart';

class DispecerHomeEmpty extends StatelessWidget {
  const DispecerHomeEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/time.svg',
              width: 75,
              height: 75,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1A7A38),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "În afara programului",
              style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Dispeceratul este închis momentan.\nNu poți înregistra comenzi noi în afara programului de lucru.",
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}