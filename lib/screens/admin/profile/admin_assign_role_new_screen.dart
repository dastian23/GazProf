import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:another_flushbar/flushbar.dart';

// --- THEME ---
import '../../../../core/theme_provider.dart';

class AdminAssignRoleNewScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const AdminAssignRoleNewScreen({super.key, required this.userId, required this.userData});

  @override
  State<AdminAssignRoleNewScreen> createState() => _AdminAssignRoleNewScreenState();
}

class _AdminAssignRoleNewScreenState extends State<AdminAssignRoleNewScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  Future<void> _saveRole() async {
    if (_selectedRole == null) {
      Flushbar(
        messageText: const Text("Selectează un rol înainte de a salva.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        backgroundColor: Colors.orange.shade800,
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
        borderRadius: BorderRadius.circular(15),
        duration: const Duration(seconds: 2),
      ).show(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
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
    final rolCurent = widget.userData['rol'] ?? 'Neatribuit';

    String initials = nume.trim().isNotEmpty ? nume.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join().toUpperCase() : "U";

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
                          CircleAvatar(radius: 20, backgroundColor: theme.roleBgNeatribuit, child: Text(initials, style: TextStyle(color: theme.roleNeatribuit, fontWeight: FontWeight.bold))),
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
                            decoration: BoxDecoration(color: theme.roleBgNeatribuit, borderRadius: BorderRadius.circular(8)),
                            child: Text("Neatribuit", style: TextStyle(color: theme.roleNeatribuit, fontSize: 11, fontWeight: FontWeight.bold)),
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
                    _buildDataRow("Rol", "Neatribuit", theme, isRed: true),
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

              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: theme.cardOutline, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Anulează", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
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
                          : const Text("Salvează rol", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(title, style: TextStyle(color: theme.textGriFix, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
    );
  }

  Widget _buildDataRow(String label, String value, ThemeProvider theme, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 13))),
          Expanded(flex: 5, child: Text(value, style: TextStyle(color: isRed ? Colors.red : theme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold))),
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