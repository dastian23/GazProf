import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'success_screen.dart';
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
    if (_nameController.text.trim().isEmpty) {
      _showError("Te rugăm să introduci numele complet.");
      return;
    }

    if (_phoneController.text.trim().length < 10) {
      _showError("Numărul de telefon este invalid.");
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showError("Adresa de email nu este validă.");
      return;
    }

    if (_passwordController.text.length < 8) {
      _showError("Parola trebuie să aibă cel puțin 8 caractere.");
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
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
              _buildTextField(hint: 'Număr de telefon', icon: Icons.phone_outlined, theme: theme, controller: _phoneController),
              const SizedBox(height: 10),
              _buildTextField(hint: 'E-mail', icon: Icons.email_outlined, theme: theme, controller: _emailController),
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

  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false, required ThemeProvider theme, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscured : false,
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