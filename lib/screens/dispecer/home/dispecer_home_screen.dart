import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:another_flushbar/flushbar.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';
import '../profile/dispecer_profile_screen.dart';

// Defining the products
class ProductItem {
  String name;
  double price;
  int quantity;
  ProductItem(this.name, this.price, this.quantity);
}

class DispecerHomeScreen extends StatefulWidget {
  const DispecerHomeScreen({super.key});

  @override
  State<DispecerHomeScreen> createState() => _DispecerHomeScreenState();
}

class _DispecerHomeScreenState extends State<DispecerHomeScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mentionsController = TextEditingController();

  bool _isLoading = false;
  bool _isMentionsExpanded = false;
  String _selectedPayment = 'cash';

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
    _phoneController.dispose();
    _addressController.dispose();
    _mentionsController.dispose();
    super.dispose();
  }

  double get _calculateTotal {
    return products.fold(0, (sum, item) => sum + (item.price * item.quantity));
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
      duration: const Duration(seconds: 3),
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
    if (!RegExp(r'^07\d{8}$').hasMatch(phone)) {
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
      await FirebaseFirestore.instance.collection('comenzi').add({
        'telefon_client': phone,
        'adresa_livrare': address,
        'produse': selectedProducts.map((p) => {
          'nume': p.name,
          'pret_unitar': p.price,
          'cantitate': p.quantity,
          'subtotal': p.price * p.quantity,
        }).toList(),
        'total_comanda': _calculateTotal,
        'tip_plata': _selectedPayment,
        'mentiuni': _mentionsController.text.trim(),
        'status': 'disponibila',
        'id_sofer': null,
        'data_creare': FieldValue.serverTimestamp(),
        'id_dispecer': FirebaseAuth.instance.currentUser?.uid,
      });

      _showMessage("Comandă creată!", isError: false);

      setState(() {
        _phoneController.clear();
        _addressController.clear();
        _mentionsController.clear();
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
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
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
                      _buildProfileCircle(userProvider.userName, theme),
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
                              style: const TextStyle(color: Color(0xFF0C9E43), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
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
                              _buildTextField(hint: 'Adresă de livrare', icon: Icons.location_on_outlined, controller: _addressController, theme: theme),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildSectionTitle("TIP BUTELIE", theme),
                        _buildCardContainer(
                          theme,
                          Column(
                            children: [
                              ...products.map((p) => _buildProductRow(p, theme)),
                              const SizedBox(height: 8),
                              Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Total comandă", style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text("${_calculateTotal.toStringAsFixed(0)} lei", style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
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
                        const SizedBox(height: 30),

                        Container(
                          width: double.infinity, height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: theme.buttonShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createOrder,
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

          if (!isKeyboardOpen)
            Positioned(
              bottom: 5 + bottomSafePadding,
              left: 18, right: 18,
              child: _buildCustomNavBar(context, theme, 0),
            ),
        ],
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
              decoration: BoxDecoration(color: const Color(0xFF1B7A3F).withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
              child: SvgPicture.asset(iconPath, width: 22, colorFilter: ColorFilter.mode(value == 'cash' ? Colors.green : theme.brandBlue, BlendMode.srcIn)),
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

  Widget _buildProfileCircle(String name, ThemeProvider theme) {
    String initials = "U";
    if (name.isNotEmpty) {
      List<String> words = name.trim().split(RegExp(r'\s+'));
      initials = words.length > 1 ? (words[0][0] + words[1][0]).toUpperCase() : words[0][0].toUpperCase();
    }
    return Container(
      width: 35, height: 35,
      decoration: BoxDecoration(color: theme.brandBlue, shape: BoxShape.circle),
      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildCustomNavBar(BuildContext context, ThemeProvider theme, int selectedIndex) {
    double screenWidth = MediaQuery.of(context).size.width - 36;
    double tabWidth = screenWidth / 4;
    const double btnSize = 52.0;
    double btnLeft = (tabWidth * selectedIndex) + (tabWidth / 2) - (btnSize / 2);
    const double btnBottom = 12.0;

    List<Map<String, dynamic>> navItems = [
      {'path': 'assets/home.svg', 'inactiveSize': 24.0, 'activeSize': 22.0},
      {'path': 'assets/file.svg', 'inactiveSize': 29.0, 'activeSize': 22.0},
      {'path': 'assets/time.svg', 'inactiveSize': 33.0, 'activeSize': 24.0},
      {'path': 'assets/user.svg', 'inactiveSize': 24.5, 'activeSize': 22.0},
    ];

    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipPath(
            clipper: _NavBarClipper(buttonLeft: btnLeft, buttonBottom: btnBottom, buttonSize: btnSize, margin: 4.0),
            child: Container(
              height: 56,
              decoration: BoxDecoration(color: theme.navBarBg, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: List.generate(4, (index) {
                  if (index == selectedIndex) return const Expanded(child: SizedBox());
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _navigate(context, index),
                      child: Center(
                        child: SvgPicture.asset(
                          navItems[index]['path'],
                          width: navItems[index]['inactiveSize'],
                          height: navItems[index]['inactiveSize'],
                          colorFilter: ColorFilter.mode(theme.navIconUnselected, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            left: btnLeft, bottom: btnBottom,
            child: Container(
              width: btnSize, height: btnSize,
              decoration: BoxDecoration(color: theme.brandBlue, shape: BoxShape.circle),
              child: Center(
                  child: SvgPicture.asset(
                      navItems[selectedIndex]['path'],
                      width: navItems[selectedIndex]['activeSize'],
                      height: navItems[selectedIndex]['activeSize'],
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  )
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == 0) return;

    Widget nextScreen;

    if (index == 1) {
      nextScreen = const Center(child: Text("Ecran Documente"));
    } else if (index == 2) {
      nextScreen = const Center(child: Text("Ecran Istoric"));
    } else if (index == 3) {
      nextScreen = const DispecerProfileScreen();
    } else {
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => nextScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

}

class _NavBarClipper extends CustomClipper<Path> {
  final double buttonLeft;
  final double buttonBottom;
  final double buttonSize;
  final double margin;

  _NavBarClipper({required this.buttonLeft, required this.buttonBottom, required this.buttonSize, required this.margin});

  @override
  Path getClip(Size size) {
    Path barPath = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(24)));
    double centerX = buttonLeft + (buttonSize / 2);
    double centerY = size.height - (buttonBottom + (buttonSize / 2));
    Path holePath = Path()..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: (buttonSize / 2) + margin));
    return Path.combine(PathOperation.difference, barPath, holePath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}