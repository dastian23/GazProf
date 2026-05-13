import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme_provider.dart';

// Import UserProvider to update global state on save
import '../../../../core/user_provider.dart';

class NiciunulPersonalDataScreen extends StatefulWidget {
  const NiciunulPersonalDataScreen({super.key});

  @override
  State<NiciunulPersonalDataScreen> createState() => _NiciunulPersonalDataScreenState();
}

class _NiciunulPersonalDataScreenState extends State<NiciunulPersonalDataScreen> {
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

  Future<void> _fetchUserData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

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
      _showSnackBar("Eroare la preluarea datelor.");
    }
  }

  Future<void> _saveData() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      _showSnackBar("Numele și telefonul sunt obligatorii.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Update Firebase
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'nume': _nameController.text.trim(),
        'telefon': _phoneController.text.trim(),
      });

      // 2. Update global UserProvider immediately so all screens refresh
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUserData(
          _nameController.text.trim(),
          Provider.of<UserProvider>(context, listen: false).userStatus, // Preserve existing status
          Provider.of<UserProvider>(context, listen: false).userEmail // Preserve existing email
        );
      }

      _showSnackBar("Datele au fost salvate cu succes!", isError: false);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar("Eroare la salvarea datelor.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orange : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        // LINE UNDER SECTION NAME & BACK-ARROW
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.sectionLabel.withOpacity(0.3),
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
              // LOGO & FLAME
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
                          color: theme.brandBlue.withOpacity(0.4),
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

              // TITLE
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Modifică datele personale",
                  style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // TEXT FIELDS
              _buildTextField(hint: 'Nume', icon: Icons.person_outline, controller: _nameController, theme: theme),
              const SizedBox(height: 15),
              _buildTextField(hint: 'Telefon', icon: Icons.phone_outlined, controller: _phoneController, theme: theme, isPhone: true),
              const SizedBox(height: 15),
              _buildTextField(hint: 'Email', icon: Icons.email_outlined, controller: _emailController, theme: theme, isReadOnly: true),

              const Spacer(flex: 2),

              // BUTON SALVEAZĂ
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
  }) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: TextStyle(color: isReadOnly ? theme.textGriFix : theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.textCard,
        prefixIcon: Icon(icon, color: theme.textFieldIcon, size: 18),
        hintText: hint,
        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
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