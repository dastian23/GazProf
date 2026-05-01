import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gazprof/auth/success_reset_password.dart';
import 'success_reset_password.dart';

class PasswordSetScreen extends StatefulWidget {
  const PasswordSetScreen({super.key});

  @override
  State<PasswordSetScreen> createState() => _PasswordSetScreenState();
}

class _PasswordSetScreenState extends State<PasswordSetScreen> {
  final Color brandBlue = const Color(0xFF0779B7);
  final Color darkGrey = const Color(0xFF312F2F);

  bool _isObscured1 = true;
  bool _isObscured2 = true;

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Padding(
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

              const SizedBox(height: 50),

              // 3. TEXT (Stilul tău de Align)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Setează o parolă nouă',
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
                  'Creează o parolă nouă. Asigură-te că este diferită de cea anterioară pentru securitatea contului. Minim 8 caractere, o litere mare și o cifră.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 4. TEXT
              _buildLabel('Parolă'),
              _buildPasswordField(
                hint: 'Introdu noua parolă',
                isObscured: _isObscured1,
                onToggle: () => setState(() => _isObscured1 = !_isObscured1),
              ),
              const SizedBox(height: 15),
              _buildLabel('Confirmă parola'),
              _buildPasswordField(
                hint: 'Reintrodu parola',
                isObscured: _isObscured2,
                onToggle: () => setState(() => _isObscured2 = !_isObscured2),
              ),

              const SizedBox(height: 115),

              // 5. BTN
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
                      MaterialPageRoute(builder: (context) => const SuccessResetPassword()),
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
                    'Actualizează',
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

  // Helper pentru etichete (Labels)
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // Helper pentru câmpurile de parolă
  Widget _buildPasswordField({required String hint, required bool isObscured, required VoidCallback onToggle}) {
    return TextField(
      obscureText: isObscured,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: darkGrey,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white70),
          onPressed: onToggle,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: brandBlue, width: 2.0),
        ),
      ),
    );
  }
}