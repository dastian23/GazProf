import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';

class ProductItem {
  String name; double price; int quantity;
  ProductItem(this.name, this.price, this.quantity);
}

class SoferCreateOrderScreen extends StatefulWidget {
  const SoferCreateOrderScreen({super.key});
  @override
  State<SoferCreateOrderScreen> createState() => _SoferCreateOrderScreenState();
}

class _SoferCreateOrderScreenState extends State<SoferCreateOrderScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mentionsController = TextEditingController();

  bool _isLoading = false;
  bool _isMentionsExpanded = false;
  String _selectedPayment = 'cash';
  String _addressType = 'intern';

  List<ProductItem> products = [
    ProductItem("Butelie 10kg", 120, 0),
    ProductItem("Butelie 11kg", 115, 0),
    ProductItem("Butelie 11kg filet", 115, 0),
    ProductItem("Butelie 35kg", 400, 0),
    ProductItem("Ambalaj", 250, 0),
    ProductItem("Ceas butelie", 40, 0),
  ];

  @override
  void dispose() {
    _phoneController.dispose(); _addressController.dispose(); _mentionsController.dispose();
    super.dispose();
  }

  double get _calculateTotal => products.fold(0, (sum, item) => sum + (item.price * item.quantity));

  void _showEditPriceDialog(ProductItem item, ThemeProvider theme) {
    final TextEditingController priceEditController = TextEditingController(text: item.price.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardCreateCommand,
        title: Text("Editează preț", style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: priceEditController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(suffixText: "lei", enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.brandBlue))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Anulează", style: TextStyle(color: theme.textSecondary))),
          TextButton(onPressed: () {
            setState(() { item.price = double.tryParse(priceEditController.text) ?? item.price; });
            Navigator.pop(context);
          }, child: Text("Salvează", style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _resetForm() {
    _phoneController.clear();
    _addressController.clear();
    _mentionsController.clear();
    setState(() {
      _selectedPayment = 'cash';
      _addressType = 'intern';
      _isMentionsExpanded = false;
      for (var product in products) {
        product.quantity = 0;
      }
    });
  }

  Future<void> _createOrder() async {
    if (_phoneController.text.isEmpty || _addressController.text.isEmpty) {
      _showMessage("Telefonul și adresa sunt obligatorii."); return;
    }
    final selectedProducts = products.where((p) => p.quantity > 0).toList();
    if (selectedProducts.isEmpty) {
      _showMessage("Selectează cel puțin un produs."); return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('comenzi').add({
        'telefon_client': _phoneController.text.trim(),
        'adresa_livrare': _addressController.text.trim(),
        'tip_adresa': _addressType,
        'produse': selectedProducts.map((p) => {'nume': p.name, 'pret_unitar': p.price, 'cantitate': p.quantity, 'subtotal': p.price * p.quantity}).toList(),
        'total_comanda': _calculateTotal,
        'tip_plata': _selectedPayment,
        'mentiuni': _mentionsController.text.trim(),
        'status': 'Alocata', // Șoferul o face -> e deja a lui
        'id_sofer': FirebaseAuth.instance.currentUser?.uid,
        'data_creare': FieldValue.serverTimestamp(),
        'creat_de': 'sofer',
      });
      _showMessage("Comandă creată!", isError: false);
      _resetForm();
      Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
    } catch (e) { _showMessage("Eroare la salvare."); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _showMessage(String msg, {bool isError = true}) {
    Flushbar(
      messageText: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: isError ? Colors.orange.shade800 : Colors.green.shade600,
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(15),
      duration: const Duration(seconds: 3),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBg, elevation: 0, automaticallyImplyLeading: false,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: theme.sectionLabel.withOpacity(0.3), height: 1.0)),
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: theme.arrowFill, shape: BoxShape.circle), child: Icon(Icons.arrow_back, color: theme.arrowIcon, size: 20)),
            ),
            Expanded(child: Text("Comandă rapidă", textAlign: TextAlign.center, style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 40),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSectionTitle("DATE CLIENT", theme),
              _buildCardContainer(theme, Column(children: [
                _buildTextField(hint: 'Telefon client', icon: Icons.phone_outlined, controller: _phoneController, theme: theme, isPhone: true),
                const SizedBox(height: 12),
                _buildTextField(hint: 'Adresă de livrare', icon: Icons.location_on_outlined, controller: _addressController, theme: theme),
                const SizedBox(height: 15),
                _buildAddressToggle(theme),
              ])),
              const SizedBox(height: 20),
              _buildSectionTitle("TIP BUTELIE", theme),
              _buildCardContainer(theme, Column(children: [
                ...products.map((p) => _buildProductRow(p, theme)),
                const Divider(height: 30),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Total comandă", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
                  Text("${_calculateTotal.toStringAsFixed(0)} lei", style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ])),
              const SizedBox(height: 20),
              _buildSectionTitle("TIP PLATĂ", theme),
              _buildCardContainer(theme, Column(children: [
                _buildPaymentRadio('Cash', 'assets/cash.svg', 'cash', theme),
                const Divider(indent: 40),
                _buildPaymentRadio('Card', 'assets/card.svg', 'card', theme),
              ])),
              const SizedBox(height: 20),
              _buildMentionsCard(theme),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                onPressed: _isLoading ? null : _createOrder,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvează comanda', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t, ThemeProvider th) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(
        t,
        style: TextStyle(
          color: th.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );
}

  Widget _buildCardContainer(ThemeProvider th, Widget c) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: th.cardCreateCommand,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: th.cardOutline),
      ),
      child: c,
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required ThemeProvider theme,
    bool isPhone = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
        prefixIcon: Icon(icon, color: theme.textFieldIcon, size: 20),
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.textCardOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.brandBlue, width: 1.5),
        ),
      ),
    );
  }
  Widget _buildAddressToggle(ThemeProvider th) {
  return Row(
    children: [
      _toggleBtn("Intern", "intern", th),
      const SizedBox(width: 10),
      _toggleBtn("Extern", "extern", th),
    ],
  );
}

  Widget _toggleBtn(String l, String v, ThemeProvider th) {
    bool isSelected = _addressType == v;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _addressType = v),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? th.brandBlue : (th.isDark ? Colors.white10 : Colors.black12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              l,
              style: TextStyle(
                color: isSelected ? Colors.white : th.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(ProductItem i, ThemeProvider th) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              i.name,
              style: TextStyle(color: th.textPrimary, fontSize: 14),
            ),
          ),
          Row(
            children: [
              Text(
                "${i.price.toStringAsFixed(0)} lei ",
                style: TextStyle(color: th.textSecondary, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => _showEditPriceDialog(i, th),
                child: SvgPicture.asset(
                  'assets/edit.svg',
                  width: 14,
                  colorFilter: ColorFilter.mode(th.brandBlue, BlendMode.srcIn),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              if (i.quantity > 0) setState(() => i.quantity--);
            },
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
              child: Icon(Icons.remove, color: th.textPrimary, size: 16),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              "${i.quantity}",
              textAlign: TextAlign.center,
              style: TextStyle(color: th.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => i.quantity++),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: th.brandBlue, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRadio(String l, String path, String v, ThemeProvider th) {
    bool isSelected = _selectedPayment == v;
    return InkWell(
      onTap: () => setState(() => _selectedPayment = v),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SvgPicture.asset(
              path,
              width: 22,
              colorFilter: ColorFilter.mode(
                isSelected ? th.brandBlue : th.textSecondary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                l,
                style: TextStyle(
                  color: th.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? th.brandBlue : th.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMentionsCard(ThemeProvider th) {
    return GestureDetector(
      onTap: () => setState(() => _isMentionsExpanded = !_isMentionsExpanded),
      child: _buildCardContainer(
        th,
        Column(
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: th.textPrimary, size: 20),
                const SizedBox(width: 10),
                Text(
                  "Mențiuni",
                  style: TextStyle(
                    color: th.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isMentionsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: th.textSecondary,
                ),
              ],
            ),
            if (_isMentionsExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: _mentionsController,
                  maxLines: 2,
                  style: TextStyle(color: th.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Instrucțiuni livrare...',
                    border: InputBorder.none,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}