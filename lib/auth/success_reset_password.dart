import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SuccessResetPassword extends StatefulWidget {
  const SuccessResetPassword({super.key});

  @override
  State<SuccessResetPassword> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessResetPassword> {
  // Animation states
  double _checkOpacity = 0.0;
  double _checkScale = 0.4;

  // Defined colors
  final Color brandBlue = const Color(0xFF0779B7);   // Fill color
  final Color outlineBlue = const Color(0xFF00A5FF); // outline & verified color

  @override
  void initState() {
    super.initState();
    // Starting the animation after 400ms delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _checkOpacity = 1.0;
          _checkScale = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. FlAME
              Stack(
                alignment: Alignment.center,
                children: [
                  // Back glow
                  Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: brandBlue.withValues(alpha: 0.4),
                          blurRadius: 45,
                          spreadRadius: 10,
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

              // 2. LOGO
              Image.asset('assets/logo_gazprof.png', height: 30),
              const Text(
                'Gestionare livrări',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 80),


              // 3. SUCCESS AT RESETING THE PASSWORD
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: brandBlue, // Fill
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: outlineBlue, // Outline
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: outlineBlue.withValues(alpha: 0.25),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _checkOpacity,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    child: AnimatedScale(
                      scale: _checkScale,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      child: SvgPicture.asset(
                        'assets/verified.svg',
                        width: 85,
                        colorFilter: ColorFilter.mode(outlineBlue, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 4. TEXT
              const Text(
                'Succes!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Felicitări! Parola ta a fost modificată! Apasă pe continuă pentru a te autentifica.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 120),



              // 6. BTN
              Container(
                width: 220,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 12,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Continuă',
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
      ),
    );
  }
}