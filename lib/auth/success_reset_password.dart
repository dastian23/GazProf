import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/theme_provider.dart';

class SuccessResetPassword extends StatefulWidget {
  const SuccessResetPassword({super.key});

  @override
  State<SuccessResetPassword> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessResetPassword> {
  // Animation states
  double _checkOpacity = 0.0;
  double _checkScale = 0.4;

  @override
  void initState() {
    super.initState();
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
    final theme = Provider.of<ThemeProvider>(context);

    // activating the status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: theme.isDark ? Brightness.dark : Brightness.light,
    ));

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 45),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 1.LOGO & FLAME
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 25,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.brandBlue.withValues(alpha: 0.4),
                          blurRadius: 35,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/flame.svg',
                    width: 45,
                    height: 65,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(theme.brandBlue, BlendMode.srcIn),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Image.asset('assets/logo_gazprof.png', height: 20),
              Text(
                'Gestionare livrări',
                style: TextStyle(color: theme.textGriFix, fontSize: 12),
              ),

              // space between logo & success icon
              const Spacer(flex: 2),

              // 2. SUCCESS ICON
              Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: theme.brandBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.outlineBlue,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.outlineBlue.withValues(alpha: 0.25),
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
                        width: 70,
                        colorFilter: ColorFilter.mode(theme.outlineBlue, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),

              // space between success icon & TEXT MESSAGE
              const SizedBox(height: 30),

              // 3. TEXT MESSAGE
              Text(
                'Succes!',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Felicitări! Parola ta a fost modificată! Apasă pe continuă pentru a te autentifica.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textGriFix, fontSize: 14),
              ),

              // space between text message & buton
              const Spacer(flex: 3),

              // 4. BUTON CONTINUĂ
              Container(
                width: 180,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.buttonOutline, width: 1.5),
                  boxShadow: theme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Continuă',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              //space to push everything up
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}