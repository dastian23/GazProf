import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme_provider.dart';

class DispecerIstoricList extends StatelessWidget {
  final List<QueryDocumentSnapshot> comenzi;

  const DispecerIstoricList({super.key, required this.comenzi});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 120),
      itemCount: comenzi.length,
      itemBuilder: (context, index) {
        final doc = comenzi[index];
        final data = doc.data() as Map<String, dynamic>;

        final adresa = data['adresa_livrare'] ?? 'Adresă lipsă';
        final blocAp = data['bloc_apartament'] ?? '';
        final adresaFull = blocAp.isNotEmpty ? '$adresa, $blocAp' : adresa;
        final telefon = data['telefon_client'] ?? 'N/A';
        final total = data['total_comanda'] ?? 0;
        final tipAdresa = data['tip_adresa'] ?? 'oras';
        final tipPlata = data['tip_plata'] ?? 'cash';
        final status = data['status'] ?? 'Finalizata';
        final idSofer = data['id_sofer'];

        final mentiuni = data['mentiuni'] ?? '';
        final produse = data['produse'] as List<dynamic>? ?? [];

        Timestamp? ts = data['data_finalizare'] ?? data['data_creare'];
        DateTime date = ts?.toDate() ?? DateTime.now();
        String formattedTime = DateFormat('HH:mm').format(date);
        String formattedDate = DateFormat('dd.MM.yyyy').format(date);

        bool isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
        String displayDate = isToday ? "Azi $formattedTime" : "$formattedDate - $formattedTime";

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

        String formatAdresa = tipAdresa.toString().toLowerCase() == 'rute' ? 'Rute' : 'Oraș';
        String formatPlata = tipPlata.toString().toLowerCase() == 'card' ? 'Card' : tipPlata.toString().toLowerCase() == 'facutara' ? 'Facutara' : 'Cash';

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: theme.cardFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.cardOutline, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adresaFull,
                          style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "$formatAdresa  •  $telefon  •  Plată: $formatPlata",
                          style: TextStyle(color: theme.textGriFix, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                          color: statusTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),

              Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 25),

              Column(
                children: produse.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.brandBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${item['cantitate']}x",
                            style: TextStyle(
                                color: theme.brandBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 11
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['nume'] ?? 'Produs',
                            style: TextStyle(color: theme.textPrimary, fontSize: 13),
                          ),
                        ),
                        Text(
                          "${item['subtotal']} lei",
                          style: TextStyle(color: theme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              if (mentiuni.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Observații: $mentiuni",
                          style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayDate,
                    style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: theme.textPrimary, fontSize: 13),
                      children: [
                        const TextSpan(text: "Total: "),
                        TextSpan(
                          text: "${total.toStringAsFixed(0)} lei",
                          style: TextStyle(
                              color: statusTextColor,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (idSofer != null)
                _buildDriverInfo(idSofer, status, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDriverInfo(String idSofer, String status, ThemeProvider theme) {
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

        String actionText = status == 'Finalizata' ? "Finalizată de" : "Anulată de";

        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.brandBlue,
                child: Text(initials, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text("$actionText: ", style: TextStyle(color: theme.textSecondary, fontSize: 12)),
              Text(displayName, style: TextStyle(color: theme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}