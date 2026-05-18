import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

// --- THEME ---
import '../../../../core/theme_provider.dart';

class DispecerIstoricEmpty extends StatelessWidget {
  const DispecerIstoricEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Center(
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
            "Istoric indisponibil",
            style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Momentan nu există\nnicio comandă pe data\n sau pe filtrul respectivă",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}