import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// --- THEME ---
import '../../../../../core/theme_provider.dart';

class AdminHomeUsersList extends StatelessWidget {
  const AdminHomeUsersList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').limit(100).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator(color: theme.brandBlue)),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final uData = users[index].data() as Map<String, dynamic>;
            String nume = uData['nume'] ?? 'Fără nume';
            String email = uData['email'] ?? 'Fără email';
            String rol = uData['rol'] ?? 'Neatribuit';

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

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardFill,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: theme.cardOutline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: rolBg,
                    child: Text(initials, style: TextStyle(color: rolText, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nume,
                          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(color: theme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: rolBg, borderRadius: BorderRadius.circular(10)),
                    child: Text(rol, style: TextStyle(color: rolText, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}