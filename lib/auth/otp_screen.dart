import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:another_flushbar/flushbar.dart';

// --- SCREENS ---
import 'success_reset_password.dart';

// --- SERVICES & PROVIDERS ---
import '../../../core/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:gazprof/services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var node in _focusNodes) node.dispose();
    for (var controller in _controllers) controller.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    String enteredCode = _controllers.map((c) => c.text).join();

    if (enteredCode.length < 4) {
      _showError("Te rugăm să introduci tot codul.");
      return;
    }

    setState(() => _isLoading = true);

    bool isValid = await AuthService().verifyOtp(widget.email, enteredCode);

    if (mounted) {
      setState(() => _isLoading = false);

      if (isValid) {
        // Navigation to success screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessResetPassword(),
          ),
        );
      } else {
        _showError("Codul este incorect sau a expirat.");
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

    // activating the status bar
    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: theme.isDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          systemOverlayStyle: overlayStyle,
          title: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.arrowFill,
                shape: BoxShape.circle,
              ),
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
                Text('Gestionare livrări', style: TextStyle(color: theme.textGriFix, fontSize: 12)),

                const Spacer(flex: 1),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifică adresa de e-mail',
                        style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Introdu codul de 4 cifre primit prin e-mail pe ${widget.email}',
                        style: TextStyle(color: theme.textGriFix, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // OTP Inputs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) => _buildOtpBox(index, theme)),
                ),

                const Spacer(flex: 2),

                // BUTTON VERIFICARE
                _buildVerifyButton(theme),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeProvider theme) {
    return Stack(
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
    );
  }

  Widget _buildVerifyButton(ThemeProvider theme) {
    return Container(
      width: 180,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.buttonOutline, width: 1.5),
        boxShadow: theme.buttonShadow,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleVerifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.brandBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
          'Verifică cod',
          style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index, ThemeProvider theme) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: theme.textCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _controllers[index].text.isNotEmpty ? theme.brandBlue : theme.textCardOutline,
            width: 1.5
        ),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textPrimary),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(counterText: "", border: InputBorder.none),
          onChanged: (value) {
            setState(() {});
            if (value.isNotEmpty && index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}