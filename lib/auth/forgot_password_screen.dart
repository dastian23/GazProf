import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final Color brandBlue = const Color(0xFF0779B7);
  final Color darkGrey = const Color(0xFF312F2F);

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
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

                      const SizedBox(height: 85),

                      // 3. TITLE & TEXT
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ai uitat parola?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Vă rugăm să introduceți adresa de e-mail pentru a primi instrucțiunile de resetare.',
                          style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.4),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 4. EMAIL
                      _buildTextField(
                        hint: 'Introduceți e-mailul',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),

                      // 5. SPACER to push down the btn
                      const SizedBox(height: 250),

                      // 6. RESET BTN
                      Container(
                        width: 240,
                        height: 55,
                        margin: const EdgeInsets.only(bottom: 50),
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
                              MaterialPageRoute(builder: (context) => const OtpScreen()),
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
                            'Resetează parola',
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: darkGrey,
        prefixIcon: Icon(icon, color: Colors.white),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
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