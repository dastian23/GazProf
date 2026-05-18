import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme_provider.dart';

class AdminIstoricEmpty extends StatelessWidget {
  const AdminIstoricEmpty({super.key});

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
              colorFilter:  ColorFilter.mode(
                theme.roleAdmin,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Istoric indisponibil",
              style: TextStyle(color: theme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Nu am găsit nicio comandă finalizată sau anulată în perioada, tipul sau pentru utilizatorul selectat.",
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