import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';
import '../../../../services/fcm_service.dart';

class SoferOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final ValueNotifier<String> paymentTypeNotifier;
  final bool _cardFidelitate;

  SoferOrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  }) : paymentTypeNotifier = ValueNotifier<String>((orderData['tip_plata'] as String?) ?? 'cash'),
       _cardFidelitate = orderData['card_fidelitate'] == true;

  double _cardDiscount(Map data) {
    final produse = data['produse'] as List? ?? [];
    double count = 0;
    for (var p in produse) {
      if (p['nume'].toString().startsWith('Butelie')) {
        count += (p['cantitate'] ?? 0).toDouble();
      }
    }
    return count * 5;
  }

  Future<void> _openNavigation(UserProvider userProvider) async {
    final address = Uri.encodeComponent('${orderData['adresa_livrare']}');
    Uri uri;
    if (userProvider.navigationApp == 'Waze') {
      uri = Uri.parse('waze://?q=$address&navigate=yes');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Eroare la deschiderea navigației: $e");
      if (userProvider.navigationApp == 'Waze') {
        Uri fallbackWaze = Uri.parse('https://www.waze.com/ul?q=$address&navigate=yes');
        await launchUrl(fallbackWaze, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _callClient() async {
    final phone = orderData['telefon_client'] ?? '';
    final String cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      bool launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      if (!launched) await launchUrl(uri);
    } catch (e) {
      debugPrint("Eroare la apelare: $e");
    }
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    await FirebaseFirestore.instance
        .collection('comenzi')
        .doc(orderId)
        .update({'status': status});
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _updatePaymentType(BuildContext context, String tipPlata) async {
    await FirebaseFirestore.instance
        .collection('comenzi')
        .doc(orderId)
        .update({'tip_plata': tipPlata});
  }

  Future<void> _showPaymentTypeDialog(BuildContext context, ThemeProvider theme, String current) async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardCreateCommand,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.cardOutline, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: theme.brandBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.brandBlue.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.swap_horiz, color: Color(0xFF0779B7), size: 32),
                ),
                const SizedBox(height: 18),
                Text("Schimbă tipul de plată", style: TextStyle(color: theme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _paymentOption(dialogContext, theme, 'cash', 'Cash', Icons.money, Colors.green, current),
                const SizedBox(height: 12),
                _paymentOption(dialogContext, theme, 'card', 'Card', Icons.credit_card, theme.brandBlue, current),
                const SizedBox(height: 12),
                _paymentOption(dialogContext, theme, 'factura', 'Factura', Icons.receipt, theme.statusTextInAsteptare, current),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    width: double.infinity, height: 48,
                    decoration: BoxDecoration(
                      color: theme.isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                    ),
                    child: Center(child: Text("Înapoi", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && context.mounted) {
      await _updatePaymentType(context, result);
      paymentTypeNotifier.value = result;
    }
  }

  Widget _paymentOption(BuildContext context, ThemeProvider theme, String value, String label, IconData icon, Color color, String current) {
    final isSelected = current.toLowerCase() == value;
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : (theme.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color.withOpacity(0.3) : (theme.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600))),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _unassignOrder(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('comenzi')
        .doc(orderId)
        .update({
      'status': 'In asteptare',
      'id_sofer': FieldValue.delete(),
    });
    FcmService().sendNewOrderNotification(orderId, orderData);
    if (context.mounted) Navigator.pop(context);
  }

  Future<bool> _showUnassignDialog(BuildContext context, ThemeProvider theme) async {
    return await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardCreateCommand,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFF6B00).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B00).withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF6B00).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.unfold_more_outlined,
                    color: Color(0xFFFF6B00),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Retragi alocarea?",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Comanda va reveni la statusul 'În așteptare' și va fi disponibilă pentru alți șoferi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: theme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Builder(builder: (context) {
                          final blocAp = orderData['bloc_apartament'] ?? '';
                          final adresaFull = blocAp.isNotEmpty ? '${orderData['adresa_livrare']}, $blocAp' : '${orderData['adresa_livrare'] ?? '-'}';
                          return Text(
                            adresaFull,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Înapoi",
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B00).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Da, retrage",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ) ?? false;
  }

  Future<bool> _showCancelDialog(BuildContext context, ThemeProvider theme) async {
    return await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardCreateCommand,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  "Anulezi comanda?",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "Această acțiune nu poate fi anulată. Comanda va fi marcată ca anulată și va dispărea din lista activă.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Info order
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: theme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Builder(builder: (context) {
                          final blocAp = orderData['bloc_apartament'] ?? '';
                          final adresaFull = blocAp.isNotEmpty ? '${orderData['adresa_livrare']}, $blocAp' : '${orderData['adresa_livrare'] ?? '-'}';
                          return Text(
                            adresaFull,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- BTNS ---
                Row(
                  children: [
                    // Btn back
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Înapoi",
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Btn Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Da, anulează",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: theme.scaffoldBg,
      systemNavigationBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Detalii comandă",
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.sectionLabel.withOpacity(0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainCard(context, theme),
              const SizedBox(height: 25),
              _buildNavigationRow(userProvider, theme),
              const SizedBox(height: 30),
              Text(
                "PROGRES LIVRARE",
                style: TextStyle(
                  color: theme.textGriFix,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              _buildDeliveryProgress(theme),
              const SizedBox(height: 40),
              _buildActionButtons(context, theme),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, ThemeProvider theme) {
    List produse = orderData['produse'] ?? [];
    String mentiuni = orderData['mentiuni'] ?? "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardCreateCommand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.cardOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.brandBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Alocată",
              style: TextStyle(
                color: theme.brandBlue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            orderData['adresa_livrare'] ?? 'Adresă lipsă',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if ((orderData['bloc_apartament'] ?? '') != '')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(orderData['bloc_apartament'], style: TextStyle(color: theme.textSecondary, fontSize: 16)),
            ),
          const SizedBox(height: 6),
          Text(
            "Contact: ${orderData['telefon_client'] ?? '-'}",
            style: TextStyle(color: theme.textGriFix, fontSize: 14),
          ),
          const SizedBox(height: 6),
          _buildPaymentRow(context, theme),
          if ((orderData['creat_de_nume'] ?? '') != '')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text("Creat de: ${orderData['creat_de_nume']} • ",
                    style: TextStyle(color: theme.textGriFix, fontSize: 12)),
                  Text(
                    () {
                      final r = (orderData['creat_de'] ?? '').toString();
                      return r == 'sofer' ? 'șofer' : r == 'dispecer' ? 'dispecer' : 'admin';
                    }(),
                    style: TextStyle(
                      color: () {
                        final r = (orderData['creat_de'] ?? '').toString();
                        return r == 'sofer' ? theme.brandBlue
                            : r == 'dispecer' ? theme.statusTextFinalizata
                            : theme.statusTextInAsteptare;
                      }(),
                      fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const Divider(height: 35, color: Colors.black12),
          Column(
            children: produse.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.brandBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        "${item['cantitate']}x",
                        style: TextStyle(
                          color: theme.brandBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['nume'] ?? 'Produs',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      "${item['subtotal']} lei",
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (mentiuni.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mentiuni,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 35, color: Colors.black12),
          () {
            final double totalOriginal = (orderData['total_comanda'] ?? 0).toDouble();
            final double discount = _cardFidelitate ? _cardDiscount(orderData) : 0;
            final double totalDisplay = totalOriginal - discount;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total de plată", style: TextStyle(color: theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (discount > 0)
                          Text("${totalOriginal.toStringAsFixed(0)} lei", style: TextStyle(color: theme.textSecondary, fontSize: 14, decoration: TextDecoration.lineThrough)),
                        Text("${totalDisplay.toStringAsFixed(0)} lei", style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(_cardFidelitate ? Icons.check_circle : Icons.card_giftcard, size: 16, color: _cardFidelitate ? Colors.green : theme.textGriFix),
                    const SizedBox(width: 6),
                    Text(
                      _cardFidelitate ? "Card fidelitate activ" : "Fără card fidelitate",
                      style: TextStyle(
                        color: _cardFidelitate ? Colors.green : theme.textGriFix,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }(),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(BuildContext context, ThemeProvider theme) {
    return ValueListenableBuilder<String>(
      valueListenable: paymentTypeNotifier,
      builder: (context, tipPlata, _) {
        final isCard = tipPlata.toLowerCase() == 'card';
        final isFactura = tipPlata.toLowerCase() == 'factura';
        final plataColor = isCard ? theme.brandBlue : isFactura ? theme.statusTextInAsteptare : Colors.green;
        return GestureDetector(
          onTap: () => _showPaymentTypeDialog(context, theme, tipPlata),
          child: Row(
            children: [
              Icon(isCard ? Icons.credit_card : isFactura ? Icons.receipt : Icons.money, size: 16, color: plataColor),
              const SizedBox(width: 6),
              Text("Plată: ", style: TextStyle(color: theme.textGriFix, fontSize: 14)),
              Text(isCard ? 'Card' : isFactura ? 'Factura' : 'Cash', style: TextStyle(color: plataColor, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 14, color: theme.textGriFix),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationRow(UserProvider up, ThemeProvider theme) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _openNavigation(up),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.brandBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.navigation_outlined, color: Colors.white),
              label: Text(
                "Navighează (${up.navigationApp})",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _callClient,
          child: Container(
            height: 50,
            width: 60,
            decoration: BoxDecoration(
              color: theme.cardCreateCommand,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.cardOutline),
            ),
            child: Icon(Icons.phone_in_talk_outlined, color: theme.brandBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryProgress(ThemeProvider theme) {
    return Row(
      children: [
        _step(true, "Alocată", theme),
        _line(true, theme),
        _step(true, "În drum", theme),
        _line(false, theme),
        _step(false, "Livrat", theme),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeProvider theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _updateStatus(context, 'Finalizata'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C9E43),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "Finalizează livrarea",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () async {
              bool confirm = await _showUnassignDialog(context, theme);
              if (confirm && context.mounted) {
                _unassignOrder(context);
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF6B00)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "Retrage alocarea",
              style: TextStyle(
                color: Color(0xFFFF6B00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () async {
              bool confirm = await _showCancelDialog(context, theme);
              if (confirm && context.mounted) {
                _updateStatus(context, 'Anulata');
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "Anulează comanda",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _step(bool active, String label, ThemeProvider theme) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? theme.brandBlue : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? theme.brandBlue : theme.textGriFix,
              width: 2,
            ),
          ),
          child: active
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? theme.textPrimary : theme.textGriFix,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _line(bool active, ThemeProvider theme) {
    return Expanded(
      child: Container(
        height: 2,
        color: active
            ? theme.brandBlue
            : theme.textGriFix.withOpacity(0.3),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }
}