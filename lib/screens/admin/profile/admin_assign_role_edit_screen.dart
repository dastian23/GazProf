import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:another_flushbar/flushbar.dart';

// --- THEME ---
import 'package:gazprof/core/constants.dart';
import '../../../../core/theme_provider.dart';

class AdminAssignRoleEditScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const AdminAssignRoleEditScreen({super.key, required this.userId, required this.userData});

  @override
  State<AdminAssignRoleEditScreen> createState() => _AdminAssignRoleEditScreenState();
}

class _AdminAssignRoleEditScreenState extends State<AdminAssignRoleEditScreen> {
  late String _originalRole;
  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _originalRole = widget.userData['rol']?.toString().toLowerCase() ?? 'neatribuit';
    _selectedRole = _originalRole;
  }

  Future<void> _saveRole() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(widget.userId).update({
        'rol': _selectedRole,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Flushbar(
        messageText: const Text("Eroare la salvare. Încearcă din nou.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(15),
        duration: const Duration(seconds: 2),
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    final nume = widget.userData['nume'] ?? 'Fără nume';
    final telefon = widget.userData['telefon'] ?? '-';
    final email = widget.userData['email'] ?? 'Fără email';

    String initials = nume.trim().isNotEmpty ? nume.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join().toUpperCase() : "U";

    Color currentRoleColor = Colors.grey;
    if (_originalRole == 'sofer') currentRoleColor = theme.roleSofer;
    if (_originalRole == 'dispecer') currentRoleColor = theme.roleDispecer;
    if (_originalRole == 'admin' || _originalRole == 'administrator') currentRoleColor = theme.roleAdmin;

    bool showConfirmation = _selectedRole != _originalRole;

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: theme.sectionLabel.withValues(alpha: 0.3), height: 1.0)),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: theme.arrowFill, shape: BoxShape.circle), child: Icon(Icons.arrow_back, color: theme.arrowIcon, size: 20)),
            ),
            Expanded(child: Text("Atribuire rol", textAlign: TextAlign.center, style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 40),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("UTILIZATOR SELECTAT", theme),

              Container(
                decoration: BoxDecoration(color: theme.cardFill, borderRadius: BorderRadius.circular(15), border: Border.all(color: theme.cardOutline)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 20, backgroundColor: currentRoleColor.withValues(alpha: 0.3), child: Text(initials, style: TextStyle(color: currentRoleColor, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nume, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(email, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: currentRoleColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                            child: Text(_originalRole[0].toUpperCase() + _originalRole.substring(1), style: TextStyle(color: currentRoleColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                    _buildDataRow("Nume", nume, theme),
                    Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                    _buildDataRow("Telefon", telefon, theme),
                    Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                    _buildDataRow("E-mail", email, theme),
                    Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                    _buildDataRow("Rol", _originalRole[0].toUpperCase() + _originalRole.substring(1), theme, customColor: currentRoleColor),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B00), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 13, height: 1.4),
                          children: [
                            const TextSpan(text: "Acest utilizator are deja rolul de "),
                            TextSpan(text: _originalRole[0].toUpperCase() + _originalRole.substring(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: ".\nSchimbarea rolului va afecta accesul său imediat."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              _buildSectionTitle("SELECTARE ROL", theme),

              Container(
                decoration: BoxDecoration(color: theme.cardFill, borderRadius: BorderRadius.circular(15), border: Border.all(color: theme.cardOutline)),
                child: Column(
                  children: [
                    _buildRoleRadio('sofer', 'Șofer', 'Preia și livrează comenzi', Icons.person_outline, theme.roleSofer, theme),
                    Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 50),
                    _buildRoleRadio('dispecer', 'Dispecer', 'Creează și gestionează comenzi', Icons.call_outlined, theme.roleDispecer, theme),
                    Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 50),
                    _buildRoleRadio('admin', 'Admin', 'Control total asupra sistemului', Icons.settings_outlined, theme.roleAdmin, theme),
                  ],
                ),
              ),

              if (showConfirmation) ...[
                const SizedBox(height: 20),
                _buildConfirmationPanel(theme),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationPanel(ThemeProvider theme) {
    String originalFormat = _originalRole[0].toUpperCase() + _originalRole.substring(1);
    String selectedFormat = _selectedRole[0].toUpperCase() + _selectedRole.substring(1);

    Color getRoleColor(String r) {
      if (r == 'sofer') return theme.roleSofer;
      if (r == 'dispecer') return theme.roleDispecer;
      if (r == 'admin') return theme.roleAdmin;
      return Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.cardOutline),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: theme.brandBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.person_outline, color: theme.brandBlue, size: 30),
          ),
          const SizedBox(height: 15),
          Text("Confirmi schimbarea rolului?", style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Accesul utilizatorului se va modifica imediat după salvare", textAlign: TextAlign.center, style: TextStyle(color: theme.textSecondary, fontSize: 12)),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: theme.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(originalFormat, style: TextStyle(color: getRoleColor(_originalRole), fontWeight: FontWeight.bold, fontSize: 14)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: Icon(Icons.arrow_forward, color: Colors.grey, size: 18)),
                Text(selectedFormat, style: TextStyle(color: getRoleColor(_selectedRole), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _selectedRole = _originalRole);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.cardOutline, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Anulează", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRole,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.brandBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Da, schimbă", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(title, style: TextStyle(color: theme.textGriFix, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
    );
  }

  Widget _buildDataRow(String label, String value, ThemeProvider theme, {Color? customColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 13))),
          Expanded(flex: 5, child: Text(value, style: TextStyle(color: customColor ?? theme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRoleRadio(String value, String title, String subtitle, IconData icon, Color iconColor, ThemeProvider theme) {
    bool isSelected = _selectedRole == value;
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? theme.brandBlue : theme.textSecondary),
          ],
        ),
      ),
    );
  }
}