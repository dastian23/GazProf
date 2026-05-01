import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'password_reset_info_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final Color brandBlue = const Color(0xFF0779B7);
  final Color darkGrey = const Color(0xFF312F2F);
  final Color lightGrey = const Color(0xFFD9D9D9);

  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

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
              decoration: BoxDecoration(color: darkGrey, shape: BoxShape.circle),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
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

            // 3. TEXT
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Verifică adresa de e-mail',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Am trimis un link de resetare la adresa de e-mail:\nIntrodu codul de 5 cifre din e-mail',
                  style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.4)),
            ),

            const SizedBox(height: 40),

           // 4. OTP ROWS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) => _buildOtpBox(index)),
            ),

            // 5. SPACER to push down the btn
            const SizedBox(height: 215),

            // 6. BTN
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
                    MaterialPageRoute(builder: (context) => const PasswordResetInfoScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Verifica cod',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 55,
      height: 65,
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black54),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          hintText: "0",
          hintStyle: TextStyle(color: Colors.black26),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 4) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}