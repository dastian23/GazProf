import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:another_flushbar/flushbar.dart';

// --- SCREENS ---
import 'otp_screen.dart';

// --- SERVICES & PROVIDERS ---
import '../../../core/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:gazprof/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty){
      _showError("Te rugăm să completezi toate câmpurile.");
      return;
    }



    setState(() => _isLoading = true);

    final String? error = await AuthService().sendOtpCode(email);

    if (mounted) {
      setState(() => _isLoading = false);

      if (error == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OtpScreen(email: email)),
        );

        Flushbar(
          messageText: const Text(
            "Codul de verificare a fost trimis!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          backgroundColor: Colors.green.shade600,
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
          borderRadius: BorderRadius.circular(15),
          duration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 400),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
        ).show(context);

      } else {
        _showError(error);
      }
    }
  }

  void _showError(String message) {
    Flushbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: theme.scaffoldBg,
    ));

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.arrowFill,
              shape: BoxShape.circle,
            ),
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
              const Spacer(flex: 1),

              // TITLE & DESCRIPTION
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ai uitat parola?',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vă rugăm să introduceți adresa de e-mail pentru a primi instrucțiunile de resetare.',
                      style: TextStyle(
                          color: theme.textGriFix,
                          fontSize: 13,
                          height: 1.4
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // INPUT FIELD
              _buildTextField(
                hint: 'Introduceți e-mailul',
                icon: Icons.email_outlined,
                controller: _emailController,
                theme: theme,
              ),
              const Spacer(flex: 2),

              // BUTTON
              Container(
                width: 210,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.buttonOutline, width: 1.5),
                  boxShadow: theme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : Text(
                    'Resetează parola',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required ThemeProvider theme,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.textCard,
        prefixIcon: Icon(icon, color: theme.textFieldIcon, size: 18),
        hintText: hint,
        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.textCardOutline, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.brandBlue, width: 1.5),
        ),
      ),
    );
  }
}