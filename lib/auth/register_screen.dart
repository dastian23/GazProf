import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'success_screen.dart';
import '../../../core/theme_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isObscured = true;
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    // activating the status bar
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
              // space to push down the logo
              const SizedBox(height: 10),

              // 1.LOGO & FLAME
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

              // space to push up the logo & everything down
              const Spacer(flex: 1),

              // 2. TITLE
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crează un cont nou',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completează datele de mai jos.',
                      style: TextStyle(color: theme.textGriFix, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // 3.TEXT FIELDS
              _buildTextField(hint: 'Nume complet', icon: Icons.person_outline, theme: theme),
              const SizedBox(height: 10),
              _buildTextField(hint: 'Număr de telefon', icon: Icons.phone_outlined, theme: theme),
              const SizedBox(height: 10),
              _buildTextField(hint: 'E-mail', icon: Icons.email_outlined, theme: theme),
              const SizedBox(height: 10),
              _buildTextField(hint: 'Parolă', icon: Icons.lock_outline, isPassword: true, theme: theme),

              const SizedBox(height: 8),
              Text(
                'Minim 8 caractere, o litere mare și o cifră',
                style: TextStyle(color: theme.textGriFix, fontSize: 11),
              ),

              // space to push down the buton & footer
              const Spacer(flex: 1),

              // 4.BUTON ÎNREGISTREAZĂ-TE
              Container(
                width: 180,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.buttonOutline, width: 1.5),
                  boxShadow: theme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SuccessScreen(email: _emailController.text)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    'Înregistrează-te',
                    style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // space between buton & footer
              const SizedBox(height: 19),

              // 5.FOOTER
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ai deja cont? ', style: TextStyle(color: theme.textGriFix, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Conectează-te',
                        style: TextStyle(color: theme.links, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              //space to push everything up
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false, required ThemeProvider theme}) {
    return TextField(
      controller: hint == 'E-mail' ? _emailController : null,
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