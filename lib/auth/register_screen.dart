import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:another_flushbar/flushbar.dart';

// --- SCREENS ---
import 'success_screen.dart';

// --- SERVICES & PROVIDERS ---
import '../../../core/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:gazprof/services/auth_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isObscured = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showError("Te rugăm să completezi toate câmpurile.");
      return;
    }

    if (!RegExp(r'^07\d{8}$').hasMatch(phone)) {
      _showError("Număr de telefon invalid.\nTrebuie să înceapă cu 07 și să aibă 10 cifre.");
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError("Adresa de e-mail este invalidă.\nTe rugăm să folosești un format corect (ex: nume@domeniu.ro).");
      return;
    }

    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));

    if (!hasMinLength || !hasUppercase || !hasDigits) {
      _showError("Parola este prea slabă.\nTrebuie să aibă minim 8 caractere, o literă mare și o cifră.");
      return;
    }

    setState(() => _isLoading = true);

    final String? error = await AuthService().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (error == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(email: _emailController.text),
          ),
        );
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
    ));

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 45),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // --- LOGO & FLAME ---
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 25, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.brandBlue.withValues(alpha: 0.4),
                          blurRadius: 35, spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/flame.svg',
                    width: 45, height: 65,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(theme.brandBlue, BlendMode.srcIn),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Image.asset('assets/logo_gazprof.png', height: 20),
              Text('Gestionare livrări', style: TextStyle(color: theme.textGriFix, fontSize: 12)),
              const Spacer(flex: 1),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Crează un cont nou', style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Completează datele de mai jos.', style: TextStyle(color: theme.textGriFix, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // --- TEXT FIELDS ---
              _buildTextField(hint: 'Nume complet', icon: Icons.person_outline, theme: theme, controller: _nameController),
              const SizedBox(height: 10),

              _buildTextField(hint: 'Număr de telefon', icon: Icons.phone_outlined, theme: theme, controller: _phoneController, isPhone: true),
              const SizedBox(height: 10),

              _buildTextField(hint: 'E-mail', icon: Icons.email_outlined, theme: theme, controller: _emailController, isEmail: true),
              const SizedBox(height: 10),

              _buildTextField(hint: 'Parolă', icon: Icons.lock_outline, isPassword: true, theme: theme, controller: _passwordController),

              const SizedBox(height: 8),
              Text('Minim 8 caractere, o litere mare și o cifră', style: TextStyle(color: theme.textGriFix, fontSize: 11)),
              const Spacer(flex: 1),

              // --- BUTTON ---
              Container(
                width: 180, height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.buttonOutline, width: 1.5),
                  boxShadow: theme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Înregistrează-te', style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 19),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ai deja cont? ', style: TextStyle(color: theme.textGriFix, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Conectează-te', style: TextStyle(color: theme.links, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPhone = false,
    bool isEmail = false,
    required ThemeProvider theme,
    required TextEditingController controller
  }) {
    TextInputType inputType = TextInputType.text;
    if (isPhone) inputType = TextInputType.phone;
    if (isEmail) inputType = TextInputType.emailAddress;

    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscured : false,
      keyboardType: inputType,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.textCard,
        prefixIcon: Icon(icon, color: theme.textFieldIcon, size: 18),
        suffixIcon: isPassword
            ? IconButton(
            icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: theme.textFieldIcon, size: 18),
            onPressed: () => setState(() => _isObscured = !_isObscured))
            : null,
        hintText: hint,
        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.textCardOutline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.brandBlue, width: 1.5)),
      ),
    );
  }
}