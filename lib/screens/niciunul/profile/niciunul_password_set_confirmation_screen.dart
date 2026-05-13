import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:another_flushbar/flushbar.dart';
import '../../../core/theme_provider.dart';
import 'package:gazprof/services/auth_service.dart';
import 'package:gazprof/auth/success_reset_password.dart';

class ChangePasswordConfirmScreen extends StatefulWidget {
  final String email;
  const ChangePasswordConfirmScreen({super.key, required this.email});

  @override
  State<ChangePasswordConfirmScreen> createState() => _ChangePasswordConfirmScreenState();
}

class _ChangePasswordConfirmScreenState extends State<ChangePasswordConfirmScreen> {
  bool _isLoading = false;

  Future<void> _handleSendReset() async {
    setState(() => _isLoading = true);

    try {
      await AuthService().sendPasswordResetEmailDirect(widget.email);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SuccessResetPassword()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Flushbar(
          messageText: const Text(
            "Eroare la trimiterea emailului. Încearcă din nou.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          backgroundColor: Colors.orange.shade800,
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
          borderRadius: BorderRadius.circular(15),
          duration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 400),
          icon: const Icon(Icons.error_outline, color: Colors.white, size: 24),
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
        ),
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: theme.arrowFill, shape: BoxShape.circle),
            child: Icon(Icons.arrow_back, color: theme.arrowIcon, size: 20),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 45),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // LOGO & FLAME
              SvgPicture.asset(
                'assets/flame.svg',
                width: 45, height: 65,
                colorFilter: ColorFilter.mode(theme.brandBlue, BlendMode.srcIn),
              ),
              const SizedBox(height: 5),
              Image.asset('assets/logo_gazprof.png', height: 20),

              const Spacer(),

              Center(
                child: Column(
                  children: [
                    Text(
                      'Schimbă parola',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Îți vom trimite un link de resetare\na parolei pe adresa de email\nassociată contului tău.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textGriFix, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              Container(
                width: 200, height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.buttonOutline, width: 1.5),
                  boxShadow: theme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Da, doresc!',
                          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}