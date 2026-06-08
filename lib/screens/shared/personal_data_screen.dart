import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:gazprof/core/constants.dart';

import '../../core/theme_provider.dart';
import '../../core/user_provider.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showFlushbar(String message, {bool isError = true}) async {
    FocusScope.of(context).unfocus();

    await Flushbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      backgroundColor: isError ? Colors.orange.shade800 : Colors.green.shade600,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
      borderRadius: BorderRadius.circular(15),
      duration: const Duration(milliseconds: 1500),
      animationDuration: const Duration(milliseconds: 400),
      icon: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: Colors.white,
          size: 24
      ),
    ).show(context);
  }

  Future<void> _fetchUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(uid).get();

      if (doc.exists) {
        setState(() {
          _nameController.text = doc['nume'] ?? '';
          _phoneController.text = doc['telefon'] ?? '';
          _emailController.text = doc['email'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showFlushbar("Eroare la preluarea datelor.");
    }
  }

  Future<void> _saveData() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      await _showFlushbar("Te rugăm să completezi toate câmpurile.");
      return;
    }

    if (!RegExp(r'^07\d{8}$').hasMatch(phone)) {
      await _showFlushbar("Număr de telefon invalid.\nTrebuie să înceapă cu 07 și să aibă 10 cifre.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      String uid = currentUser.uid;

      await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(uid).update({
        'nume': name,
        'telefon': phone,
      });

      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUserData(
            name,
            Provider.of<UserProvider>(context, listen: false).userRole,
            email
        );
      }

      await _showFlushbar("Datele au fost salvate cu succes!", isError: false);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      await _showFlushbar("Eroare la salvarea datelor.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: theme.scaffoldBg,
    ));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.sectionLabel.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
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
            Expanded(
              child: Text(
                "Date personale",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.brandBlue))
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 45),
          child: Column(
            children: [
              const SizedBox(height: 30),
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

              const Spacer(flex: 1),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Modifică datele personale",
                  style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(hint: 'Nume', icon: Icons.person_outline, controller: _nameController, theme: theme),
              const SizedBox(height: 15),
              _buildTextField(hint: 'Telefon', icon: Icons.phone_outlined, controller: _phoneController, theme: theme, isPhone: true),
              const SizedBox(height: 15),
              _buildTextField(hint: 'Email', icon: Icons.email_outlined, controller: _emailController, theme: theme, isReadOnly: true),

              const Spacer(flex: 2),

              Container(
                width: 180,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.buttonOutline, width: 1.5),
                  boxShadow: theme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.brandBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                      'Salvează',
                      style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required ThemeProvider theme,
    bool isPhone = false,
    bool isReadOnly = false,
    int maxLength = 200,
  }) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      maxLength: maxLength,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      style: TextStyle(color: isReadOnly ? theme.textGriFix : theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.textCard,
        prefixIcon: Icon(icon, color: theme.textFieldIcon, size: 18),
        hintText: hint,
        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.textCardOutline, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isReadOnly ? theme.textCardOutline : theme.brandBlue, width: 1.5),
        ),
      ),
    );
  }
}
