import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// --- THEME ---
import '../../../../core/theme_provider.dart';

class SoferHomeEmpty extends StatelessWidget {
  final String titlu;
  final String mesaj;

  const SoferHomeEmpty({super.key, required this.titlu, required this.mesaj});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/delivery.svg',
              width: 90,
              // Albastrul cerut
              colorFilter: ColorFilter.mode(theme.brandBlue, BlendMode.srcIn),
            ),
            const SizedBox(height: 25),
            Text(
              titlu,
              style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              mesaj,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondary, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}