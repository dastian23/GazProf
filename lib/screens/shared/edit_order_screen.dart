import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_flushbar/flushbar.dart';

import '../../models/product_item.dart';
import '../../core/theme_provider.dart';
import '../../core/user_provider.dart';
import '../../services/fcm_service.dart';

class EditOrderScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const EditOrderScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _mentionsController;

  bool _isLoading = false;
  bool _isProductsLoading = true;
  bool _isMentionsExpanded = false;
  bool _cardFidelitate = false;
  String _selectedPayment = 'cash';
  String _addressType = 'oras';
  String? _driverName;

  List<ProductItem> products = [];

  String get _status => widget.orderData['status'] ?? 'In asteptare';

  @override
  void initState() {
    super.initState();

    final data = widget.orderData;
    _phoneController = TextEditingController(text: data['telefon_client'] ?? '');
    _addressController = TextEditingController(text: data['adresa_livrare'] ?? '');
    _addressLine2Controller = TextEditingController(text: data['bloc_apartament'] ?? '');
    _mentionsController = TextEditingController(text: data['mentiuni'] ?? '');
    _cardFidelitate = data['card_fidelitate'] == true;
    _selectedPayment = data['tip_plata'] ?? 'cash';
    _addressType = data['tip_adresa'] ?? 'oras';

    _loadProducts();
    _loadDriverName();
  }

  Future<void> _loadDriverName() async {
    final idSofer = widget.orderData['id_sofer'];
    if (idSofer == null || idSofer.toString().isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(idSofer.toString()).get();
      if (doc.exists && mounted) {
        setState(() => _driverName = (doc.data() as Map)['nume'] ?? 'Șofer');
      }
    } catch (e) {
      debugPrint("Eroare _loadDriverName: $e");
    }
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('produse')
          .orderBy('pozitie')
          .get();

      if (snapshot.docs.isEmpty) {
        final defaultProducts = [
          {"nume": "Butelie 10kg", "pret": 120.0},
          {"nume": "Butelie 11kg", "pret": 115.0},
          {"nume": "Butelie 11kg filet", "pret": 115.0},
          {"nume": "Butelie 35kg", "pret": 400.0},
          {"nume": "Ambalaj", "pret": 250.0},
          {"nume": "Ceas butelie", "pret": 40.0},
        ];
        for (int i = 0; i < defaultProducts.length; i++) {
          await FirebaseFirestore.instance.collection('produse').add({
            'nume': defaultProducts[i]['nume'],
            'pret': defaultProducts[i]['pret'],
            'pozitie': i,
          });
        }
        return _loadProducts();
      }

      if (mounted) {
        final existingProducts = (widget.orderData['produse'] as List?)
                ?.cast<Map<String, dynamic>>() ?? [];

        setState(() {
          products = snapshot.docs.map((doc) {
            final name = doc['nume'] ?? 'Produs';
            final defaultPrice = (doc['pret'] ?? 0.0).toDouble();
            final existing = existingProducts.cast<Map<String, dynamic>>().firstWhere(
              (e) => e['nume'] == name,
              orElse: () => <String, dynamic>{},
            );
            final qty = (existing['cantitate'] ?? 0);
            final price = existing.isNotEmpty
                ? (existing['pret_unitar'] ?? defaultPrice).toDouble()
                : defaultPrice;
            return ProductItem(name, price, (qty is int) ? qty : (qty as num).toInt());
          }).toList();
          _isProductsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Eroare la încărcarea produselor: $e");
      if (mounted) setState(() => _isProductsLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _addressLine2Controller.dispose();
    _mentionsController.dispose();
    super.dispose();
  }

  double get _calculateTotal {
    if (_selectedPayment == 'factura') return 0;
    return products.fold(0, (val, item) => val + (item.price * item.quantity));
  }

  double get _discountAmount {
    if (!_cardFidelitate || _selectedPayment == 'factura') return 0;
    return products
        .where((p) => p.name.startsWith('Butelie'))
        .fold(0, (sum, p) => sum + p.quantity) * 5;
  }

  void _showMessage(String message, {bool isError = true}) {
    Flushbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      backgroundColor: isError ? Colors.orange.shade800 : Colors.green.shade600,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
      borderRadius: BorderRadius.circular(15),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 400),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
        size: 24,
      ),
    ).show(context);
  }

  void _showEditPriceDialog(ProductItem item, ThemeProvider theme) {
    final controller = TextEditingController(text: item.price.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardCreateCommand,
        title: Text("Editează preț", style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            suffixText: "lei",
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.brandBlue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Anulează", style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                item.price = double.tryParse(controller.text) ?? item.price;
              });
              Navigator.pop(context);
            },
            child: Text("Salvează", style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveOrder() async {
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (phone.isEmpty || address.isEmpty) {
      _showMessage("Telefonul și adresa sunt obligatorii.");
      return;
    }
    if (!RegExp(r'^(?:\+?[1-9]\d{3,14}|07\d{8}|03\d{8}|02\d{8})$').hasMatch(phone)) {
      _showMessage("Număr de telefon invalid.");
      return;
    }

    final selectedProducts = products.where((p) => p.quantity > 0).toList();
    if (selectedProducts.isEmpty) {
      _showMessage("Selectează cel puțin un produs.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('comenzi')
          .doc(widget.orderId)
          .update({
        'telefon_client': phone,
        'adresa_livrare': address,
        'bloc_apartament': _addressLine2Controller.text.trim(),
        'tip_adresa': _addressType,
        'produse': selectedProducts.map((p) => {
          'nume': p.name,
          'pret_unitar': p.price,
          'cantitate': p.quantity,
          'subtotal': p.price * p.quantity,
        }).toList(),
        'total_comanda': _calculateTotal,
        'card_fidelitate': _cardFidelitate,
        'tip_plata': _selectedPayment,
        'mentiuni': _mentionsController.text.trim(),
      });

      if (mounted) {
        _showMessage("Modificări salvate!", isError: false);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      _showMessage("Eroare la salvare.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unassignDriver() async {
    await FirebaseFirestore.instance
        .collection('comenzi')
        .doc(widget.orderId)
        .update({
      'status': 'In asteptare',
      'id_sofer': FieldValue.delete(),
    });
    FcmService().sendNewOrderNotification(widget.orderId, widget.orderData);
    if (mounted) {
      _showMessage("Șoferul a fost retras.", isError: false);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  Future<void> _urgentOrder() async {
    final driverId = widget.orderData['id_sofer']?.toString();
    if (driverId == null || driverId.isEmpty) return;

    await FcmService().sendUrgentNotification(
      widget.orderId,
      widget.orderData,
      driverId,
    );
    if (mounted) {
      _showMessage("Notificare de urgență trimisă șoferului!", isError: false);
    }
  }

  Future<bool> _showUrgentDialog(ThemeProvider theme) async {
    final adresa = widget.orderData['adresa_livrare'] ?? '';
    final numeSofer = _driverName ?? 'șofer';
    return await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardCreateCommand,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.red.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2)
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.alarm, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              Text("Urgentează comanda?",
                  style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: "Șoferul ",
                  style: TextStyle(color: theme.textSecondary, fontSize: 13),
                  children: [
                    TextSpan(
                      text: numeSofer,
                      style: TextStyle(
                          color: theme.brandBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          " va primi o notificare să livreze comanda cât mai rapid.",
                      style:
                          TextStyle(color: theme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              if (adresa.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                          child: Text(adresa,
                              style: TextStyle(
                                  color: theme.textPrimary, fontSize: 13))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.cardOutline),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text("Anulează",
                          style: TextStyle(
                              color: theme.textSecondary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Da, trimite",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showUnassignDialog(ThemeProvider theme) async {
    final adresa = widget.orderData['adresa_livrare'] ?? '';
    return await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardCreateCommand,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.3), width: 1),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.unfold_more_outlined, color: Color(0xFFFF6B00), size: 28),
              ),
              const SizedBox(height: 16),
              Text("Retragi alocarea?", style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: "Comanda va reveni la statusul ",
                  style: TextStyle(color: theme.textSecondary, fontSize: 13),
                  children: [
                    TextSpan(
                      text: "«În așteptare»",
                      style: TextStyle(color: const Color(0xFFFF6B00), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: " și șoferul va fi notificat.",
                      style: TextStyle(color: theme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              if (adresa.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: theme.statusTextInAsteptare, size: 16),
                      const SizedBox(width: 8),
                      Flexible(child: Text(adresa, style: TextStyle(color: theme.textPrimary, fontSize: 13))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.cardOutline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text("Înapoi", style: TextStyle(color: theme.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Da, retrage", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userRole =
        Provider.of<UserProvider>(context, listen: false).userRole;
    final bool canUrge = userRole == 'admin' || userRole == 'dispecer';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: theme.arrowFill, shape: BoxShape.circle), child: Icon(Icons.arrow_back, color: theme.arrowIcon, size: 20)),
            ),
            Expanded(child: Text("Editează comanda", textAlign: TextAlign.center, style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900))),
            const SizedBox(width: 40),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // --- CREATOR & STATUS INFO ---
                    _buildInfoBanner(theme),
                    const SizedBox(height: 16),

                    // --- DATE CLIENT ---
                    _buildSectionTitle("DATE CLIENT", theme),
                    _buildCardContainer(
                      theme,
                      Column(
                        children: [
                          _buildTextField(hint: 'Număr telefon client', icon: Icons.phone_outlined, controller: _phoneController, theme: theme, isPhone: true),
                          const SizedBox(height: 12),
                          _buildTextField(hint: 'Strada', icon: Icons.location_on_outlined, controller: _addressController, theme: theme),
                          const SizedBox(height: 12),
                          _buildTextField(hint: 'Bloc, Apartament (opțional)', icon: Icons.home_outlined, controller: _addressLine2Controller, theme: theme),
                          const SizedBox(height: 15),
                          _buildAddressTypeToggle(theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- TIP BUTELIE ---
                    _buildSectionTitle("TIP BUTELIE", theme),
                    _buildCardContainer(
                      theme,
                      _isProductsLoading
                          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                          : Column(
                              children: [
                                ...products.map((p) => _buildProductRow(p, theme)),
                                const SizedBox(height: 8),
                                Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Total comandă", style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (_cardFidelitate)
                                          Text("${_calculateTotal.toStringAsFixed(0)} lei",
                                            style: TextStyle(color: theme.textSecondary, fontSize: 12, decoration: TextDecoration.lineThrough)),
                                        Text("${(_calculateTotal - _discountAmount).toStringAsFixed(0)} lei",
                                          style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                if (_selectedPayment == 'factura')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("Facturare ulterioară — totalul este 0 lei",
                                      style: TextStyle(color: theme.statusTextInAsteptare, fontSize: 12, fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),

                    // --- TIP PLATĂ ---
                    _buildSectionTitle("TIP PLATĂ", theme),
                    _buildCardContainer(
                      theme,
                      Column(
                        children: [
                          _buildPaymentRadio('Cash', 'Plata la livrare', 'assets/cash.svg', 'cash', theme),
                          Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 40),
                          _buildPaymentRadio('Card', 'Plata cu cardul', 'assets/card.svg', 'card', theme),
                          Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1, indent: 40),
                          _buildPaymentRadio('Factura', 'Plată cu factură', 'assets/invoice.svg', 'factura', theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- CARD FIDELITATE ---
                    _buildSectionTitle("CARD FIDELITATE", theme),
                    _buildCardContainer(
                      theme,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.card_giftcard, color: theme.brandBlue, size: 20),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Card fidelitate", style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                                  Text("Reducere de 5 lei", style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _cardFidelitate,
                            onChanged: (v) => setState(() => _cardFidelitate = v),
                            activeThumbColor: theme.brandBlue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- MENTIUNI ---
                    GestureDetector(
                      onTap: () => setState(() => _isMentionsExpanded = !_isMentionsExpanded),
                      child: _buildCardContainer(
                        theme,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/message.svg', width: 20, colorFilter: ColorFilter.mode(theme.textPrimary, BlendMode.srcIn)),
                                const SizedBox(width: 10),
                                Text("Mențiuni", style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: theme.isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(10)),
                                  child: Text("opțional", style: TextStyle(color: theme.textSecondary, fontSize: 10)),
                                ),
                                const Spacer(),
                                Icon(_isMentionsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: theme.textSecondary),
                              ],
                            ),
                            if (_isMentionsExpanded) ...[
                              const SizedBox(height: 15),
                              TextField(
                                controller: _mentionsController,
                                maxLines: 3,
                                style: TextStyle(color: theme.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Adaugă instrucțiuni...',
                                  hintStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
                                  filled: true,
                                  fillColor: theme.isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- UNASSIGN BUTTON (doar Alocata) ---
                    if (_status == 'Alocata') ...[
                      _buildUnassignSection(theme),
                      const SizedBox(height: 16),
                    ],

                    // --- URGENT BUTTON (doar admin/dispecer, doar Alocata) ---
                    if (_status == 'Alocata' && canUrge) ...[
                      _buildUrgentSection(theme),
                      const SizedBox(height: 16),
                    ],

                    // --- SAVE BUTTON ---
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: theme.buttonShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading || _isProductsLoading ? null : _saveOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: theme.brandBlue, width: 1.5),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text('Salvează modificări', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ThemeProvider theme) {
    final creatDeNume = widget.orderData['creat_de_nume'] ?? '';
    final creatDe = widget.orderData['creat_de'] ?? '';
    final statusColor = _status == 'Alocata' ? theme.statusTextAlocata
        : _status == 'Finalizata' ? theme.statusTextFinalizata
        : _status == 'Anulata' ? theme.statusTextAnulata
        : theme.statusTextInAsteptare;
    final displayStatus = _status == 'In asteptare' ? 'În așteptare'
        : _status == 'Alocata' ? 'Alocată'
        : _status == 'Finalizata' ? 'Finalizată'
        : _status == 'Anulata' ? 'Anulată'
        : _status;

    final adresa = widget.orderData['adresa_livrare'] ?? '';
    final blocAp = widget.orderData['bloc_apartament'] ?? '';
    final adresaFull = blocAp.isNotEmpty ? '$adresa, $blocAp' : adresa;
    final telefon = widget.orderData['telefon_client'] ?? '-';
    final tipPlata = widget.orderData['tip_plata'] ?? 'cash';
    final formatPlata = tipPlata.toLowerCase() == 'card' ? 'Card' : tipPlata.toLowerCase() == 'factura' ? 'Factura' : 'Cash';
    final tipAdresa = widget.orderData['tip_adresa'] ?? 'oras';
    final formatAdresa = tipAdresa.toLowerCase() == 'rute' ? 'Rute' : 'Oraș';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _status == 'Alocata' || _status == 'In asteptare'
              ? statusColor.withValues(alpha: 0.4)
              : theme.cardOutline,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(formatAdresa, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
              Text(" • ", style: TextStyle(color: theme.textSecondary, fontSize: 12)),
              Text(telefon, style: TextStyle(color: theme.brandBlue, fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(displayStatus, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                tipPlata == 'card' ? Icons.credit_card : tipPlata == 'factura' ? Icons.receipt : Icons.money,
                size: 14,
                color: tipPlata == 'card' ? theme.brandBlue : tipPlata == 'factura' ? theme.statusTextInAsteptare : Colors.green,
              ),
              const SizedBox(width: 6),
              Text("Plată: $formatPlata", style: TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          if (creatDeNume.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, color: theme.textSecondary, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text("Creat de: $creatDeNume • ",
                    style: TextStyle(color: theme.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                  ),
                Text(
                  creatDe == 'sofer' ? 'șofer' : creatDe == 'dispecer' ? 'dispecer' : 'admin',
                  style: TextStyle(
                    color: creatDe == 'sofer' ? theme.brandBlue
                        : creatDe == 'dispecer' ? theme.statusTextFinalizata
                        : theme.statusTextInAsteptare,
                    fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          if (_driverName != null && _status == 'Alocata') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: theme.statusTextAlocata, size: 14),
                const SizedBox(width: 6),
                Text("Șofer: ", style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                Text(_driverName!, style: TextStyle(color: theme.statusTextAlocata, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnassignSection(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: const Color(0xFFFF6B00), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text("Retrage șoferul", style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: "Comanda va reveni la ",
              style: TextStyle(color: theme.textSecondary, fontSize: 12),
              children: [
                TextSpan(
                  text: "«În așteptare»",
                  style: TextStyle(color: const Color(0xFFFF6B00), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: " și șoferul va fi înștiințat.",
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await _showUnassignDialog(theme);
                if (confirmed && mounted) _unassignDriver();
              },
              icon: const Icon(Icons.unfold_more_outlined, size: 18),
              label: const Text("Retrage alocarea"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B00),
                side: const BorderSide(color: Color(0xFFFF6B00)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentSection(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.alarm, color: Colors.red, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text("Urgentează comanda",
                    style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Șoferul va primi o notificare să livreze cât mai rapid.",
            style: TextStyle(color: theme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await _showUrgentDialog(theme);
                if (confirmed && mounted) _urgentOrder();
              },
              icon: const Icon(Icons.alarm_add, size: 18),
              label: const Text("Trimite notificare de urgență"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- SHARED UI HELPERS (identical to admin_documente_screen) ----

  Widget _buildSectionTitle(String title, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(color: theme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildCardContainer(ThemeProvider theme, Widget child) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardCreateCommand,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.cardOutline, width: 1.0),
      ),
      child: child,
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, required TextEditingController controller, required ThemeProvider theme, bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
        prefixIcon: Icon(icon, color: theme.textFieldIcon, size: 20),
        hintText: hint,
        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.textCardOutline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.brandBlue, width: 1.5)),
      ),
    );
  }

  Widget _buildAddressTypeToggle(ThemeProvider theme) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _addressType = 'oras'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _addressType == 'oras' ? theme.brandBlue : (theme.isDark ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _addressType == 'oras' ? theme.brandBlue : Colors.transparent),
              ),
              child: Center(
                child: Text('Oraș', style: TextStyle(color: _addressType == 'oras' ? Colors.white : theme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _addressType = 'rute'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _addressType == 'rute' ? theme.brandBlue : (theme.isDark ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _addressType == 'rute' ? theme.brandBlue : Colors.transparent),
              ),
              child: Center(
                child: Text('Rute', style: TextStyle(color: _addressType == 'rute' ? Colors.white : theme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(ProductItem item, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(item.name, style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Row(
            children: [
              Text("${item.price.toStringAsFixed(0)} lei ", style: TextStyle(color: theme.textSecondary, fontSize: 13)),
              GestureDetector(
                onTap: () => _showEditPriceDialog(item, theme),
                child: SvgPicture.asset('assets/edit.svg', width: 14, colorFilter: ColorFilter.mode(theme.brandBlue, BlendMode.srcIn)),
              ),
            ],
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              if (item.quantity > 0) setState(() => item.quantity--);
            },
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: theme.isDark ? Colors.white12 : Colors.black12, shape: BoxShape.circle),
              child: Icon(Icons.remove, color: theme.textPrimary, size: 16),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text("${item.quantity}", textAlign: TextAlign.center, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () => setState(() => item.quantity++),
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: theme.brandBlue, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRadio(String title, String subtitle, String iconPath, String value, ThemeProvider theme) {
    bool isSelected = _selectedPayment == value;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: value == 'factura' ? theme.statusCardInAsteptare : (value == 'card' ? theme.statusCardAlocata : theme.statusCardFinalizata),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 22,
                colorFilter: ColorFilter.mode(value == 'cash' ? Colors.green : value == 'factura' ? theme.statusTextInAsteptare : theme.brandBlue, BlendMode.srcIn),
              ),
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
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? theme.brandBlue : theme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
