import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:gazprof/core/constants.dart';
import '../../../../core/theme_provider.dart';
import '../../../../core/time_indicator.dart';

class SoferHomeList extends StatefulWidget {
  final List<QueryDocumentSnapshot> comenzi;

  const SoferHomeList({super.key, required this.comenzi});

  @override
  State<SoferHomeList> createState() => _SoferHomeListState();
}

class _SoferHomeListState extends State<SoferHomeList> {
  Timer? _timer;

  @override
  void initState() {
    _timer = Timer.periodic(AppConstants.refreshInterval, (_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _cardDiscount(Map data) {
    final produse = data['produse'] as List? ?? [];
    double count = 0;
    for (var p in produse) {
      if (p['nume'].toString().startsWith('Butelie')) {
        count += (p['cantitate'] ?? 0).toDouble();
      }
    }
    return count * AppConstants.discountPerBottle;
  }

  Future<void> _takeOrder(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final ref = FirebaseFirestore.instance.collection(FirestoreCollections.orders).doc(id);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('Comanda nu mai există.');
        final currentStatus = (snap.data() as Map<String, dynamic>)['status'] as String?;
        if (currentStatus != OrderStatus.waiting.label) {
          throw Exception('Comanda a fost deja preluată de altcineva.');
        }
        tx.update(ref, {
          'status': OrderStatus.allocated.label,
          'id_sofer': uid,
          'data_preluare': FieldValue.serverTimestamp(),
        });
      });
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange.shade800),
        );
      }
    } catch (e) {
      debugPrint('Eroare alocare comandă: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final comenzi = widget.comenzi;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comenzi.length,
      itemBuilder: (context, index) {
        final doc = comenzi[index];
        final data = doc.data() as Map<String, dynamic>;

        Timestamp? ts = data['data_creare'];
        DateTime date = ts?.toDate() ?? DateTime.now();
        String formattedTime = DateFormat('HH:mm').format(date);

        List produse = data['produse'] ?? [];
        String mentiuni = data['mentiuni'] ?? "";

        final adresa = data['adresa_livrare'] ?? 'Adresă necunoscută';
        final blocAp = data['bloc_apartament'] ?? '';
        final adresaFull = blocAp.isNotEmpty ? '$adresa, $blocAp' : adresa;
        final telefon = data['telefon_client'] ?? '-';
        String tipAdresa = data['tip_adresa'] ?? AppConstants.addressTypeCity;
        String tipPlata = data['tip_plata'] ?? PaymentType.cash.value;
        bool cardFidelitate = data['card_fidelitate'] == true;
        double totalOriginal = (data['total_comanda'] ?? 0).toDouble();
        double discount = cardFidelitate ? _cardDiscount(data) : 0;
        double totalDisplay = totalOriginal - discount;

        final creatDeNume = data['creat_de_nume'] ?? '';
        final creatDeRol = data['creat_de'] ?? '';

        String formatAdresa = tipAdresa.toString().toLowerCase() == AppConstants.addressTypeRoute ? 'Rute' : 'Oraș';
        String formatPlata = tipPlata.toString().toLowerCase() == PaymentType.card.value ? 'Card' : tipPlata.toString().toLowerCase() == PaymentType.invoice.value ? 'Factura' : 'Cash';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: theme.cardCreateCommand,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: getTimeBorderColor(date), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adresaFull,
                          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "$formatAdresa  •  $telefon",
                          style: TextStyle(color: theme.textGriFix, fontSize: 11),
                        ),
                        Text(
                          "Plată: $formatPlata",
                          style: TextStyle(color: theme.textGriFix, fontSize: 11),
                        ),
                        if (creatDeNume.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text("Creat de: $creatDeNume • ",
                                    style: TextStyle(color: theme.textGriFix, fontSize: 11),
                                    overflow: TextOverflow.ellipsis),
                                  ),
                                Text(
                                  creatDeRol == 'sofer' ? 'șofer' : creatDeRol == 'dispecer' ? 'dispecer' : 'admin',
                                  style: TextStyle(
                                    color: creatDeRol == 'sofer' ? theme.brandBlue
                                        : creatDeRol == 'dispecer' ? theme.statusTextFinalizata
                                        : theme.statusTextInAsteptare,
                                    fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "In asteptare",
                      style: TextStyle(color: Color(0xFFFF6B00), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const Divider(height: 25, color: Colors.black12),

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
                            style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item['nume'] ?? 'Produs', style: TextStyle(color: theme.textPrimary, fontSize: 13)),
                        ),
                        Text("${item['subtotal']} lei", style: TextStyle(color: theme.textSecondary, fontSize: 12)),
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
                    color: theme.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.orange.withValues(alpha: 0.05),
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
                          style: TextStyle(color: theme.textPrimary, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 20, color: Colors.black12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Azi $formattedTime", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (cardFidelitate)
                        Text("Card -${discount.toStringAsFixed(0)} lei", style: TextStyle(color: theme.brandBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: theme.textPrimary, fontSize: 13),
                          children: [
                            const TextSpan(text: "Total: "),
                            TextSpan(
                              text: "${totalDisplay.toStringAsFixed(0)} lei",
                              style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => _takeOrder(doc.id),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.cardOutline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Preia comanda", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}