import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';

// --- MODELS ---
import 'package:gazprof/core/constants.dart';
import 'package:gazprof/models/product_item.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';
import '../../../../core/products_provider.dart';
import '../../../services/fcm_service.dart';

// --- SHELL ---
import 'package:gazprof/screens/dispecer/dispecer_shell.dart';

// --- WIDGETS ---
import 'package:gazprof/widgets/profile_avatar.dart';

// --- COMPONENTS ---
import 'dispecer_home_empty.dart';

class DispecerHomeScreen extends StatefulWidget {
  const DispecerHomeScreen({super.key});

  @override
  State<DispecerHomeScreen> createState() => _DispecerHomeScreenState();
}

class _DispecerHomeScreenState extends State<DispecerHomeScreen> with WidgetsBindingObserver {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _mentionsController = TextEditingController();

  bool _isLoading = false;
  bool _isMentionsExpanded = false;
  bool _cardFidelitate = false;
  String _selectedPayment = 'cash';
  String _addressType = 'oras';

  List<ProductItem> products = [];

  late DateTime _startOfShift;
  late DateTime _endOfShift;
  late bool _inProgram;

  void _recomputeShift() {
    final now = DateTime.now();
    final newStart = DateTime(now.year, now.month, now.day, 7, 0, 0);
    final newEnd = DateTime(now.year, now.month, now.day + 1, 1, 0, 0);
    final newInProgram = now.isAfter(newStart) && now.isBefore(newEnd);
    if (newStart != _startOfShift || newEnd != _endOfShift || newInProgram != _inProgram) {
      setState(() {
        _startOfShift = newStart;
        _endOfShift = newEnd;
        _inProgram = newInProgram;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _startOfShift = DateTime(now.year, now.month, now.day, 7, 0, 0);
    _endOfShift = DateTime(now.year, now.month, now.day + 1, 1, 0, 0);
    _inProgram = now.isAfter(_startOfShift) && now.isBefore(_endOfShift);
  }

  /// Apelat din build() când ProductsProvider semnalează că lista s-a schimbat.
  /// Merge produs cu produs prin lista nouă și păstrează cantitățile deja introduse.
  void _reloadProducts(ProductsProvider productsProvider) {
    productsProvider.loadIfNeeded().then((_) {
      if (!mounted) return;
      final newProducts = productsProvider.freshCopy();
      setState(() {
        for (final newP in newProducts) {
          final existing = products.where((p) => p.name == newP.name).firstOrNull;
          newP.quantity = existing?.quantity ?? 0;
        }
        products = newProducts;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
    _addressController.dispose();
    _addressLine2Controller.dispose();
    _mentionsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recomputeShift();
  }





  double get _calculateTotal {
    if (_selectedPayment == 'factura') return 0;
    return products.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get _discountAmount {
    if (!_cardFidelitate || _selectedPayment == 'factura') return 0;
    return products
        .where((p) => p.name.startsWith('Butelie'))
        .fold(0, (sum, p) => sum + p.quantity) * 5;
  }

  // --- EDIT PRICE LOGIC  ---
  void _showEditPriceDialog(ProductItem item, ThemeProvider theme) {
    final TextEditingController priceEditController =
    TextEditingController(text: item.price.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardCreateCommand,
        title: Text("Editează preț", style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: priceEditController,
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
                item.price = double.tryParse(priceEditController.text) ?? item.price;
              });
              Navigator.pop(context);
            },
            child: Text("Salvează", style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
      duration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 400),
      icon: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: Colors.white,
          size: 24
      ),
    ).show(context);
  }

  Future<void> _createOrder() async {
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
      final orderData = {
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
        'status': OrderStatus.waiting.label,
        'id_sofer': null,
        'data_creare': FieldValue.serverTimestamp(),
        'id_dispecer': FirebaseAuth.instance.currentUser?.uid,
        'creat_de': 'dispecer',
        'creat_de_nume': Provider.of<UserProvider>(context, listen: false).userName,
      };

      final docRef = await FirebaseFirestore.instance
          .collection(FirestoreCollections.orders)
          .add(orderData);

      FcmService().sendNewOrderNotification(docRef.id, orderData);

      _showMessage("Comandă creată!", isError: false);

      setState(() {
        _phoneController.clear();
        _addressController.clear();
        _addressLine2Controller.clear();
        _mentionsController.clear();
        _addressType = 'oras';
        _cardFidelitate = false;
        _isMentionsExpanded = false;
        for (var p in products) { p.quantity = 0; }
      });
    } catch (e) {
      _showMessage("Eroare la salvare.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Ascultăm ProductsProvider — când invalidate() e apelat de admin,
    // notifyListeners() declanșează acest rebuild și reîncărcăm lista
    final productsProvider = context.watch<ProductsProvider>();
    if (!productsProvider.isLoaded && !productsProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reloadProducts(productsProvider);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: theme.isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBg,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/logo_gazprof.png', height: 20),
                        GestureDetector(
                          onTap: () => _navigate(context, 3),
                          child: ProfileAvatar(name: userProvider.userName, color: theme.brandBlue),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bun venit,", style: TextStyle(color: theme.textGriFix, fontSize: 13)),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(text: userProvider.userName),
                              const TextSpan(text: " - ", style: TextStyle(fontWeight: FontWeight.normal)),
                              TextSpan(
                                text: userProvider.userRole,
                                style: const TextStyle(color: Color(0xFF1A7A38), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                      ],
                    ),
                  ),

                  // --- DYNAMIC ZONE ---
                  Expanded(
                    child: !_inProgram
                        ? const DispecerHomeEmpty()
                        : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Column(
                        children: [
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

                          _buildSectionTitle("TIP BUTELIE", theme),
                          _buildCardContainer(
                            theme,
                            products.isEmpty
                                ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
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
                                      maxLength: 500,
                                      inputFormatters: [LengthLimitingTextInputFormatter(500)],
                                      maxLines: 3,
                                      style: TextStyle(color: theme.textPrimary, fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Adaugă instrucțiuni...',
                                        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 13),
                                        counterText: '',
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
                          const SizedBox(height: 30),

                          Container(
                            width: double.infinity, height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: theme.buttonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading || products.isEmpty ? null : _createOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: theme.cardOutline, width: 1.0),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text('Crează comandă', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),

                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),


          ],
        ),
      ),
    );
  }

  // --- HELPERS  ---

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

  Widget _buildTextField({required String hint, required IconData icon, required TextEditingController controller, required ThemeProvider theme, bool isPhone = false, int maxLength = 200}) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: TextStyle(color: theme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
        prefixIcon: Icon(icon, color: theme.textFieldIcon, size: 20),
        hintText: hint,
        hintStyle: TextStyle(color: theme.textSecondary, fontSize: 14),
        counterText: '',
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
            onTap: () { if (item.quantity > 0) setState(() => item.quantity--); },
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
                  colorFilter: ColorFilter.mode(value == 'cash' ? Colors.green : value == 'factura' ? theme.statusTextInAsteptare : theme.brandBlue, BlendMode.srcIn)
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

  void _navigate(BuildContext context, int index) {
    DispecerShellState.of(context)?.switchTab(index);
  }

}

