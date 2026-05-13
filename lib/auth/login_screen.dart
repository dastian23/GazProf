import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gazprof/screens/sofer/home/sofer_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:another_flushbar/flushbar.dart';

// --- SERVICES & PROVIDERS ---
import 'package:gazprof/services/auth_service.dart';
import '../../../core/theme_provider.dart';
import '../../../core/user_provider.dart';

// --- SCREENS ---
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../screens/niciunul/home/niciunul_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIN LOGIC ---
  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError("Te rugăm să completezi toate câmpurile.");
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService().loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        String rol = result['rol'] ?? 'neatribuit';
        String nume = result['nume'];
        //String status = result['status'] ?? 'neatribuit';

        // ROUTE TO APPROPRIATE SCREEN by ROLE
        if (rol == 'neatribuit') {
          // 1. Saving the data globally in Provider
          Provider.of<UserProvider>(context, listen: false).setUserData(nume, rol, _emailController.text.trim());

          // 2. Navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NiciunulHomeScreen(),
            ),
          );
        } else if (rol == 'sofer') {
            // 1. Saving the data globally in Provider
            Provider.of<UserProvider>(context, listen: false).setUserData(nume, rol, _emailController.text.trim());

            // 2. Navigation
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SoferHomeScreen(),
              ),
            );
        } else if (rol == 'dispecer') {
          _showError("Ecranul Dispecer este în lucru!");
        } else if (rol == 'admin') {
          _showError("Ecranul Admin este în lucru!");
        } else {
          // Fallback
          Provider.of<UserProvider>(context, listen: false).setUserData(nume, rol, _emailController.text.trim());

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const NiciunulHomeScreen(),
            ),
          );
        }
      } else {
        _showError(result['error']);
      }
    }
  }

  // --- GOOGLE LOGIN LOGIC ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final result = await AuthService().loginWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        String rol = result['rol'] ?? 'neatribuit';
        String nume = result['nume'];
        //String status = result['status'] ?? 'neatribuit';

        if (rol == 'neatribuit') {
          Provider.of<UserProvider>(context, listen: false).setUserData(nume, rol, _emailController.text.trim());
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NiciunulHomeScreen()),
          );
        } else if (rol == 'sofer') {
            Provider.of<UserProvider>(context, listen: false).setUserData(nume, rol, _emailController.text.trim());
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SoferHomeScreen()),
            );
        } else if (rol == 'dispecer') {
          _showError("Ecranul Dispecer este în lucru!");
        } else if (rol == 'admin') {
          _showError("Ecranul Admin este în lucru!");
        } else {
          Provider.of<UserProvider>(context, listen: false).setUserData(nume, rol, _emailController.text.trim());
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NiciunulHomeScreen()),
          );
        }
      } else {
        _showError(result['error']);
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

  // --- UI PART ---
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 25),

              // LOGO & FLAME
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 25, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: theme.brandBlue.withValues(alpha: 0.4), blurRadius: 35, spreadRadius: 6),
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
              const SizedBox(height: 8),
              Image.asset('assets/logo_gazprof.png', height: 20),
              Text('Gestionare livrări', style: TextStyle(color: theme.textGriFix, fontSize: 12)),

              const Spacer(flex: 2),

              // INPUT FIELD
              _buildTextField(hint: 'Introduceți e-mailul', icon: Icons.email_outlined, theme: theme, controller: _emailController),
              const SizedBox(height: 18),
              _buildTextField(hint: 'Introduceți parola', icon: Icons.lock_outline, isPassword: true, theme: theme, controller: _passwordController),

              // BUTTON "AI UITAT PAROLA?"
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: Text('Ai uitat parola?', style: TextStyle(color: theme.links, fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // BUTTON PRINCIPAL (CONECTEAZĂ-TE)
              Container(
                width: 180, height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.buttonOutline, width: 1.5),
                  boxShadow: theme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Conectează-te', style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 25),
              const Text('sau', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 25),

              // 5. BUTTON GOOGLE
              Container(
                width: double.infinity, height: 45,
                decoration: BoxDecoration(
                  color: theme.buttonCard,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.buttonCardOutline, width: 1.2),
                ),
                child: InkWell(
                  onTap: _isLoading ? null : _handleGoogleLogin,
                  borderRadius: BorderRadius.circular(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/google_logo.png', height: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Conectează-te cu Google', style: TextStyle(color: theme.textPrimary, fontSize: 14), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // FOOTER
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Nu ești înregistrat? ', style: TextStyle(color: theme.textGriFix, fontSize: 13)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: Text('Înregistrează-te', style: TextStyle(color: theme.links, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
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
    required ThemeProvider theme,
    required TextEditingController controller
  }) {
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
          onPressed: () => setState(() => _isObscured = !_isObscured),
        )
            : null,
        hintText: hint,
        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.textCardOutline, width: 1.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.brandBlue, width: 1.5)),
      ),
    );
  }
}