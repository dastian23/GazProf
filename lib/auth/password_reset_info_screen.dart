import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gazprof/auth/password_set_screen.dart';
import 'password_set_screen.dart';

class PasswordResetInfoScreen extends StatelessWidget {
  const PasswordResetInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color brandBlue = const Color(0xFF0779B7);
    final Color darkGrey = const Color(0xFF312F2F);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: darkGrey,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. FLAME
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: brandBlue.withValues(alpha: 0.5),
                        blurRadius: 50,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/flame.svg',
                  width: 69,
                  height: 95,
                  fit: BoxFit.fill,
                  colorFilter: ColorFilter.mode(brandBlue, BlendMode.srcIn),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. LOGO GAZPROF
            Image.asset(
              'assets/logo_gazprof.png',
              width: 171,
              height: 21,
              fit: BoxFit.contain,
            ),
            const Text(
              'Gestionare livrări',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 85),

            // 3. TEXT
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Resetare parolă',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Parola ta a fost resetată cu succes. Apasă pe confirmă pentru a seta o parolă nouă.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 335),

            // 4. BTN
            Container(
              width: 240,
              height: 55,
              margin: const EdgeInsets.only(bottom: 80),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PasswordSetScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Confirmă',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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