import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  final Color darkGrey = const Color(0xFF312F2F);
  final Color brandBlue = const Color(0xFF0779B7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),
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
                const SizedBox(height: 50),

                // 3. TEXT FIELDS (Email & Password)
                _buildTextField(
                  hint: 'Introduceți e-mailul',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  hint: 'Introduceți parola',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                // 4. Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'Ai uitat parola?',
                      style: TextStyle(color: Color(0xFF00B4D8), fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 5. BTN
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
                      // Aici vom pune logica de navigare
                      print("Buton apăsat!");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Conectează-te',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),
                const Text('sau', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 25),

                // 6. BUTON GOOGLE
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: darkGrey,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/google_logo.png', height: 24),
                        const Text(
                          '  Conectează-te cu google',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // 7. FOOTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Nu ești înregistrat? ',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Înregistrează-te',
                        style: TextStyle(
                          color: Color(0xFF00B4D8),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      obscureText: isPassword ? _isObscured : false,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: darkGrey,
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
            icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
            onPressed: () => setState(() => _isObscured = !_isObscured))
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60, fontSize: 16),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }
}