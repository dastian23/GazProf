import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/theme_provider.dart';
import 'success_reset_password.dart';
import 'package:gazprof/services/auth_service.dart';

class PasswordSetScreen extends StatefulWidget {
  final String email;
  const PasswordSetScreen({super.key, required this.email});

  @override
  State<PasswordSetScreen> createState() => _PasswordSetScreenState();
}

class _PasswordSetScreenState extends State<PasswordSetScreen> {
  bool _isObscured1 = true;
  bool _isObscured2 = true;
  bool _isLoading = false;
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  Future<void> _handleUpdate() async {
    if (_passController.text.length < 8) {
      _showError("Minim 8 caractere necesare.");
      return;
    }
    if (_passController.text != _confirmPassController.text) {
      _showError("Parolele nu coincid.");
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthService().updatePasswordManual(widget.email, _passController.text);

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SuccessResetPassword()));
      } else {
        _showError(error);
      }
    }
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.orange));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
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
            width: 40, height: 40,
            decoration: BoxDecoration(color: theme.arrowFill, shape: BoxShape.circle),
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
              _buildLogo(theme),
              const SizedBox(height: 5),
              Image.asset('assets/logo_gazprof.png', height: 20),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Setează o parolă nouă', style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Creează o parolă nouă pentru contul ${widget.email}', style: TextStyle(color: theme.textGriFix, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _buildField('Parolă', _passController, _isObscured1, () => setState(() => _isObscured1 = !_isObscured1), theme),
              const SizedBox(height: 15),
              _buildField('Confirmă parola', _confirmPassController, _isObscured2, () => setState(() => _isObscured2 = !_isObscured2), theme),
              const Spacer(flex: 2),
              _buildButton(theme),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController ctrl, bool obs, VoidCallback toggle, ThemeProvider theme) {
    return TextField(
      controller: ctrl,
      obscureText: obs,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true, fillColor: theme.textCard,
        prefixIcon: Icon(Icons.lock_outline, color: theme.textFieldIcon, size: 18),
        suffixIcon: IconButton(icon: Icon(obs ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18), onPressed: toggle),
        hintText: hint,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.textCardOutline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.brandBlue, width: 1.5)),
      ),
    );
  }

  Widget _buildButton(ThemeProvider theme) {
    return Container(
      width: 200, height: 45,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), border: Border.all(color: theme.buttonOutline, width: 1.5)),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleUpdate,
        style: ElevatedButton.styleFrom(backgroundColor: theme.brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) :  Text('Actualizează', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLogo(ThemeProvider theme) {
    return SvgPicture.asset('assets/flame.svg', width: 45, height: 65, colorFilter: ColorFilter.mode(theme.brandBlue, BlendMode.srcIn));
  }
}