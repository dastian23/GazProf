import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Necesar pentru SystemChrome

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

class SoferOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const SoferOrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });


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
    
    final Uri uri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );

    try {
      bool launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalNonBrowserApplication
      );
      
      if (!launched) {
        await launchUrl(uri);
      }
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

  Future<bool> _showConfirmationDialog(BuildContext context, ThemeProvider theme, String titlu, String mesaj) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardCreateCommand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titlu, style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(mesaj, style: TextStyle(color: theme.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Nu, înapoi", style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Da, anulează", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
      systemNavigationBarColor: theme.scaffoldBg, // Aceasta rezolvă problema cu butoanele de jos
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
          style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: theme.sectionLabel.withOpacity(0.3), height: 1.0),
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
              _buildMainCard(theme),
              const SizedBox(height: 25),
              _buildNavigationRow(userProvider, theme),
              const SizedBox(height: 30),
              Text(
                "PROGRES LIVRARE",
                style: TextStyle(color: theme.textGriFix, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const SizedBox(height: 20),
              _buildDeliveryProgress(theme),
              const SizedBox(height: 40),
              _buildActionButtons(context, theme, orderData),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(ThemeProvider theme) {
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
            child: Text("Alocată", style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 15),
          Text(orderData['adresa_livrare'] ?? 'Adresă lipsă', style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Contact: ${orderData['telefon_client'] ?? '-'}", style: TextStyle(color: theme.textGriFix, fontSize: 14)),
          const Divider(height: 35, color: Colors.black12),
          Column(
            children: produse.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: theme.brandBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: Text("${item['cantitate']}x", style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item['nume'] ?? 'Produs', style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
                    Text("${item['subtotal']} lei", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
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
                  Expanded(child: Text(mentiuni, style: TextStyle(color: theme.textPrimary, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4))),
                ],
              ),
            ),
          ],
          const Divider(height: 35, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total de plată", style: TextStyle(color: theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              Text("${orderData['total_comanda']} lei", style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.navigation_outlined, color: Colors.white),
              label: Text("Navighează (${up.navigationApp})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _callClient,
          child: Container(
            height: 50, width: 60,
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

  Widget _buildActionButtons(BuildContext context, ThemeProvider theme, Map<String, dynamic> orderData) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () async {
              bool confirm = await _showConfirmationDialog(context, theme, "Finalizare livrare", "Confirmi livrarea produselor și încasarea sumei?");
              if (confirm) _updateStatus(context, 'Finalizata');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C9E43),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Finalizează livrarea", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 52,
          child: OutlinedButton(
            onPressed: () async {
              bool confirm = await _showConfirmationDialog(context, theme, "Confirmare anulare", "Ești sigur că vrei să anulezi această comandă?");
              if (confirm) _updateStatus(context, 'Anulata');
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Anulează comanda", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _step(bool active, String label, ThemeProvider theme) {
    return Column(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: active ? theme.brandBlue : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: active ? theme.brandBlue : theme.textGriFix, width: 2),
          ),
          child: active ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: active ? theme.textPrimary : theme.textGriFix, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _line(bool active, ThemeProvider theme) {
    return Expanded(child: Container(height: 2, color: active ? theme.brandBlue : theme.textGriFix.withOpacity(0.3), margin: const EdgeInsets.only(bottom: 16)));
  }
}