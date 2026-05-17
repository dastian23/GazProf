import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// --- THEME ---
import '../../../../core/theme_provider.dart';

// --- SCREENS ---
import 'admin_assign_role_new_screen.dart';
import 'admin_assign_role_edit_screen.dart';

class AdminGestionareScreen extends StatelessWidget {
  const AdminGestionareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: theme.sectionLabel.withValues(alpha: 0.3), height: 1.0),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: theme.arrowFill, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back, color: theme.arrowIcon, size: 20),
              ),
            ),
            Expanded(
              child: Text(
                "Gestionare utilizatori",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('data_creare', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.brandBlue));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nu există utilizatori.", style: TextStyle(color: theme.textSecondary)));
          }

          final users = snapshot.data!.docs;

          final unassignedUsers = users.where((doc) {
            final rol = (doc.data() as Map<String, dynamic>)['rol']?.toString().toLowerCase() ?? 'neatribuit';
            return rol == 'neatribuit' || rol.isEmpty;
          }).toList();

          final activeUsers = users.where((doc) {
            final rol = (doc.data() as Map<String, dynamic>)['rol']?.toString().toLowerCase() ?? 'neatribuit';
            return rol != 'neatribuit' && rol.isNotEmpty;
          }).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unassignedUsers.isNotEmpty) ...[
                  _buildSectionTitle("FĂRĂ ROL ATRIBUIT", theme),
                  ...unassignedUsers.map((doc) => _buildUserTile(context, doc, theme, isUnassigned: true)),
                  const SizedBox(height: 20),
                ],

                if (activeUsers.isNotEmpty) ...[
                  _buildSectionTitle("UTILIZATORI ACTIVI", theme),
                  ...activeUsers.map((doc) => _buildUserTile(context, doc, theme, isUnassigned: false)),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title,
        style: TextStyle(color: theme.textGriFix, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, QueryDocumentSnapshot doc, ThemeProvider theme, {required bool isUnassigned}) {
    final data = doc.data() as Map<String, dynamic>;
    final nume = data['nume'] ?? 'Fără nume';
    final email = data['email'] ?? 'Fără email';
    final rol = data['rol'] ?? 'Neatribuit';

    List<String> words = nume.trim().split(RegExp(r'\s+'));
    String initials = "U";
    if (words.isNotEmpty) {
      initials = words.length > 1 ? (words[0][0] + words[1][0]).toUpperCase() : words[0][0].toUpperCase();
    }

    Color rolBg;
    Color rolText;

    if (rol.toLowerCase() == 'sofer') {
      rolBg = theme.roleBgSofer;
      rolText = theme.roleSofer;
    } else if (rol.toLowerCase() == 'dispecer') {
      rolBg = theme.roleBgDispecer;
      rolText = theme.roleDispecer;
    } else if (rol.toLowerCase() == 'admin' || rol.toLowerCase() == 'administrator') {
      rolBg = theme.roleBgAdmin;
      rolText = theme.roleAdmin;
    } else {
      rolBg = theme.roleBgNeatribuit;
      rolText = theme.roleNeatribuit;
    }

    return GestureDetector(
      onTap: () {
        if (isUnassigned) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAssignRoleNewScreen(userId: doc.id, userData: data)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAssignRoleEditScreen(userId: doc.id, userData: data)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardFill,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.cardOutline),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: rolBg,
              child: Text(initials, style: TextStyle(color: rolText, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nume, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(email, style: TextStyle(color: theme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: rolBg, borderRadius: BorderRadius.circular(10)),
              child: Text(rol.isNotEmpty ? rol[0].toUpperCase() + rol.substring(1) : 'Neatribuit',
                  style: TextStyle(color: rolText, fontSize: 12, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }
}