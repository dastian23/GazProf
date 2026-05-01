import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'success_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isObscured = true;
  final Color darkGrey = const Color(0xFF312F2F);
  final Color brandBlue = const Color(0xFF0779B7);
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const SizedBox(height: 50),
                // 1. LOGO & FLAME
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
                    // Flacăra propriu-zisă
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

                Image.asset('assets/logo_gazprof.png', height: 30),
                const Text(
                  'Gestionare livrări',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 45),

                // 2. TITLU
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Crează un cont nou',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Completează datele de mai jos pentru a începe.',
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 35),

                // 3. TEXT FIELDS
                _buildTextField(hint: 'Nume complet', icon: Icons.person_outline),
                const SizedBox(height: 20),
                _buildTextField(hint: 'Număr de telefon', icon: Icons.phone_outlined),
                const SizedBox(height: 20),
                _buildTextField(hint: 'E-mail', icon: Icons.email_outlined),
                const SizedBox(height: 20),
                _buildTextField(
                  hint: 'Parolă',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                // 4. TEXT INSTRUCȚIUNI (14px)
                const SizedBox(height: 12),
                const Text(
                  'Minim 8 caractere, o litere mare și o cifră',
                  style: TextStyle(color: Colors.white54, fontSize: 14), // 14px
                ),

                const SizedBox(height: 45),

                // 5. BUTON ÎNREGISTREAZĂ-TE (Glow neon + 16px)
                Container(
                  width: 220,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        spreadRadius: 1,
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuccessScreen(email: _emailController.text),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Înregistrează-te',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 6. FOOTER (14px)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                        'Ai deja cont? ',
                        style: TextStyle(color: Colors.white70, fontSize: 14)
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Conectează-te',
                        style: TextStyle(
                            color: Color(0xFF00B4D8),
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: hint == 'E-mail' ? _emailController : null,
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
          borderSide: const BorderSide(color: Colors.white, width: 1.5), // Outline alb
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: brandBlue, width: 2.0),
        ),
      ),
    );
  }
}