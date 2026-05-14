import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// --- THEME ---
import '../../../../core/theme_provider.dart';

class DispecerDocumenteList extends StatelessWidget {
  final List<QueryDocumentSnapshot> comenzi;

  const DispecerDocumenteList({super.key, required this.comenzi});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    // CALCULATE THE COUNTERS
    int countDisponibile = comenzi.where((c) => c['status'] == 'In asteptare').length;
    int countPreluate = comenzi.where((c) => c['status'] == 'Alocata').length;
    int countLivrate = comenzi.where((c) => c['status'] == 'Finalizata').length;
    int countAnulate = comenzi.where((c) => c['status'] == 'Anulata').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(child: _buildCounterBox("Disponibile", countDisponibile, theme.statusTextInAsteptare, theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildCounterBox("Preluate", countPreluate, theme.statusTextAlocata, theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildCounterBox("Livrate", countLivrate, theme.statusTextFinalizata, theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildCounterBox("Anulate", countAnulate, theme.statusTextAnulata, theme)),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // --- TEXT LIVE ORDERS ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Text(
            "COMENZI LIVE",
            style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),

        // --- CARD LIST ---
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 120),
            itemCount: comenzi.length,
            itemBuilder: (context, index) {
              final doc = comenzi[index];
              final data = doc.data() as Map<String, dynamic>;

              final adresa = data['adresa_livrare'] ?? 'Adresă lipsă';
              final telefon = data['telefon_client'] ?? 'N/A';
              final total = data['total_comanda'] ?? 0;
              final tipAdresa = data['tip_adresa'] ?? 'intern';
              final status = data['status'] ?? 'In asteptare';
              final idSofer = data['id_sofer'];

              String produseStr = '';
              if (data['produse'] != null) {
                final prodList = data['produse'] as List<dynamic>;
                produseStr = prodList.map((p) => "${p['cantitate']}x ${p['nume']}").join(', ');
              }

              String timeStr = "Azi 14:30";
              if (data['data_creare'] != null) {
                final ts = data['data_creare'] as Timestamp;
                final dt = ts.toDate();
                timeStr = "Azi ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              }

              Color statusTextColor;
              Color statusBgColor;
              String displayStatus = status;

              if (status == 'In asteptare') {
                statusTextColor = theme.statusTextInAsteptare;
                statusBgColor = theme.statusCardInAsteptare;
                displayStatus = "În așteptare";
              } else if (status == 'Alocata') {
                statusTextColor = theme.statusTextAlocata;
                statusBgColor = theme.statusCardAlocata;
                displayStatus = "Alocată";
              } else if (status == 'Finalizata') {
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

                        // FUTURE BUILDER: BRING SOFER DATA FRON FIREBASE
                        if (status != 'In asteptare' && idSofer != null)
                          _buildDriverInfo(idSofer, theme),

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

                    Text(
                      "${tipAdresa == 'intern' ? 'Intern' : 'Extern'}  -  $telefon",
                      style: TextStyle(color: theme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(timeStr, style: TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const Text("  -  ", style: TextStyle(color: Colors.grey)),
                        Expanded(
                          child: Text(
                            produseStr,
                            style: TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text("  -  ", style: TextStyle(color: Colors.grey)),
                        Text(
                          "${total.toStringAsFixed(0)} lei",
                          style: TextStyle(color: theme.statusTextInAsteptare, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- WIDGET FOR FETCHING SOFER DATA
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

  // --- HELPER METERS ---
  Widget _buildCounterBox(String label, int count, Color counterColor, ThemeProvider theme) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.cardOutline, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(color: counterColor, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: theme.textSecondary, fontSize: 9, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}