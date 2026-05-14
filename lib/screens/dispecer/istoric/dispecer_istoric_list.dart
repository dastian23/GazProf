import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// --- THEME ---
import '../../../../core/theme_provider.dart';

class DispecerIstoricList extends StatelessWidget {
  final List<QueryDocumentSnapshot> comenzi;

  const DispecerIstoricList({super.key, required this.comenzi});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 5, bottom: 120),
      itemCount: comenzi.length,
      itemBuilder: (context, index) {
        final doc = comenzi[index];
        final data = doc.data() as Map<String, dynamic>;

        // Fetching data
        final adresa = data['adresa_livrare'] ?? 'Adresă lipsă';
        final telefon = data['telefon_client'] ?? 'N/A';
        final total = data['total_comanda'] ?? 0;
        final tipAdresa = data['tip_adresa'] ?? 'intern';
        final status = data['status'] ?? 'Finalizata';
        final idSofer = data['id_sofer'];

        // Format products
        String produseStr = '';
        if (data['produse'] != null) {
          final prodList = data['produse'] as List<dynamic>;
          produseStr = prodList.map((p) => "${p['cantitate']}x ${p['nume']}").join(', ');
        }

        // Format time
        String timeStr = "Azi 14:30";
        if (data['data_creare'] != null) {
          final ts = data['data_creare'] as Timestamp;
          final dt = ts.toDate();
          final isToday = DateTime.now().day == dt.day && DateTime.now().month == dt.month && DateTime.now().year == dt.year;

          if (isToday) {
            timeStr = "Azi ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          } else {
            timeStr = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          }
        }

        // Status colors
        Color statusTextColor;
        Color statusBgColor;
        String displayStatus = status;

        if (status == 'Finalizata') {
          statusTextColor = theme.statusTextFinalizata;
          statusBgColor = theme.statusCardFinalizata;
          displayStatus = "Finalizată";
        } else {
          statusTextColor = theme.statusTextAnulata;
          statusBgColor = theme.statusCardAnulata;
          displayStatus = "Anulată";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: theme.cardFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.cardOutline, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ROW 1: Adresă, Șofer, Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      adresa,
                      style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  if (idSofer != null) _buildDriverInfo(idSofer, theme),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(color: statusTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ROW 2: Details
              Text(
                "${tipAdresa == 'intern' ? 'Intern' : 'Extern'}  -  $telefon",
                style: TextStyle(color: theme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),

              Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
              const SizedBox(height: 12),

              // ROW 3: Hour, Product, Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(timeStr, style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Text("  -  ", style: TextStyle(color: Colors.grey)),
                  Expanded(
                    child: Text(
                      produseStr,
                      style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text("  -  ", style: TextStyle(color: Colors.grey)),
                  Text(
                    "${total.toStringAsFixed(0)} lei",
                    style: TextStyle(color: statusTextColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FETCHING SOFER DATA
  Widget _buildDriverInfo(String idSofer, ThemeProvider theme) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(idSofer).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String fullName = userData['nume'] ?? 'Necunoscut';

        List<String> words = fullName.trim().split(RegExp(r'\s+'));
        String initials = "U";
        String displayName = fullName;

        if (words.isNotEmpty) {
          if (words.length > 1) {
            initials = (words[0][0] + words[1][0]).toUpperCase();
            displayName = "${words[0]} ${words[1][0].toUpperCase()}.";
          } else {
            initials = words[0][0].toUpperCase();
            displayName = words[0];
          }
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: theme.brandBlue,
              child: Text(initials, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 4),
            Text(displayName, style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }
}