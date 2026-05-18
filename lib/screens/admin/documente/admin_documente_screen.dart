import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gazprof/screens/admin/istoric/admin_istoric_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:another_flushbar/flushbar.dart';

// --- MODELS ---
import 'package:gazprof/models/product_item.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';
import '../../../services/fcm_service.dart';

// --- WIDGETS ---
import 'package:gazprof/widgets/nav_bar_clipper.dart';

// --- SCREENS ---
import 'package:gazprof/screens/admin/home/admin_home_screen.dart';
import 'package:gazprof/screens/admin/profile/admin_profile_screen.dart';

class AdminDocumenteScreen extends StatefulWidget {
  const AdminDocumenteScreen({super.key});

  @override
  State<AdminDocumenteScreen> createState() => _AdminDocumenteScreenState();
}

class _AdminDocumenteScreenState extends State<AdminDocumenteScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mentionsController = TextEditingController();

  bool _isLoading = false;
  bool _isProductsLoading = true; 
  bool _isMentionsExpanded = false;
  String _selectedPayment = 'cash';
  String _addressType = 'intern';

  List<ProductItem> products = []; 

  @override
  void initState() {
    super.initState();
    _loadLiveProducts(); 
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _mentionsController.dispose();
    super.dispose();
  }

  // ✅ REPARAT: Adăugat înapoi getter-ul pentru calculul totalului comenzii
  double get _calculateTotal {
    return products.fold(0, (val, item) => val + (item.price * item.quantity));
  }

  Future<void> _loadLiveProducts() async {
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
        return _loadLiveProducts(); 
      }

      if (mounted) {
        setState(() {
          products = snapshot.docs.map((doc) {
            final data = doc.data();
            return ProductItem(
              data['nume'] ?? 'Produs',
              (data['pret'] ?? 0.0).toDouble(),
              0,
            );
          }).toList();
          _isProductsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Eroare la încărcarea produselor din Firebase: $e");
      if (mounted) {
        setState(() => _isProductsLoading = false);
      }
    }
  }

  // --- EDIT PRICE LOGIC ---
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
        size: 24,
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
      final orderData = {
        'telefon_client': phone,
        'adresa_livrare': address,
        'tip_adresa': _addressType,
        'produse': selectedProducts.map((p) => {
          'nume': p.name,
          'pret_unitar': p.price,
          'cantitate': p.quantity,
          'subtotal': p.price * p.quantity,
        }).toList(),
        'total_comanda': _calculateTotal,
        'tip_plata': _selectedPayment,
        'mentiuni': _mentionsController.text.trim(),

        // --- ADMIN SETTINGS ---
        'status': 'In asteptare',
        'id_sofer': null,
        'data_creare': FieldValue.serverTimestamp(),
        'creat_de': 'admin',
      };

      final docRef = await FirebaseFirestore.instance
          .collection('comenzi')
          .add(orderData);

      FcmService().sendNewOrderNotification(docRef.id, orderData);

      _showMessage("Comandă creată și trimisă în așteptare!", isError: false);

      setState(() {
        _phoneController.clear();
        _addressController.clear();
        _mentionsController.clear();
        _addressType = 'intern';
        _isMentionsExpanded = false;
        for (var p in products) {
          p.quantity = 0;
        }
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

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // --- HEADER CURAT DINAMIC ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Creare comandă",
                        style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: _buildProfileCircle(userProvider.userName, theme),
                      ),
                    ],
                  ),
                ),
                Divider(color: theme.sectionLabel.withValues(alpha: 0.3), height: 1.0),

                // --- FORMULAR ---
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
                              const SizedBox(height: 15),
                              _buildAddressTypeToggle(theme),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildSectionTitle("TIP BUTELIE", theme),
                        _buildCardContainer(
                          theme,
                          _isProductsLoading
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
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: theme.buttonShadow,
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading || _isProductsLoading ? null : _createOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: theme.cardOutline, width: 1.0),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text('Emite comanda', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
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

          // Hide the navbar if keyboard is up
          if (!isKeyboardOpen)
            Positioned(
              bottom: 5 + bottomSafePadding,
              left: 18, right: 18,
              child: _buildCustomNavBar(context, theme, 1),
            ),
        ],
      ),
    );
  }

  // --- HELPERS UI ---
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
            onTap: () => setState(() => _addressType = 'intern'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _addressType == 'intern' ? theme.brandBlue : (theme.isDark ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _addressType == 'intern' ? theme.brandBlue : Colors.transparent),
              ),
              child: Center(
                child: Text('Intern', style: TextStyle(color: _addressType == 'intern' ? Colors.white : theme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _addressType = 'extern'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _addressType == 'extern' ? theme.brandBlue : (theme.isDark ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _addressType == 'extern' ? theme.brandBlue : Colors.transparent),
              ),
              child: Center(
                child: Text('Extern', style: TextStyle(color: _addressType == 'extern' ? Colors.white : theme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
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
              if (item.quantity > 0) {
                setState(() => item.quantity--);
              }
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
                color: value == 'card' ? theme.statusCardAlocata : theme.statusCardFinalizata,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SvgPicture.asset(
                  iconPath,
                  width: 22,
                  colorFilter: ColorFilter.mode(value == 'cash' ? Colors.green : theme.brandBlue, BlendMode.srcIn)
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
            clipper: NavBarClipper(buttonLeft: btnLeft, buttonBottom: btnBottom, buttonSize: btnSize, margin: 4.0),
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

  // --- NAVIGATE LOGIC ---
  void _navigate(BuildContext context, int index) {
    if (index == 1) return;

    Widget nextScreen;
    if (index == 0) {
      nextScreen = const AdminHomeScreen();
    } else if (index == 2) {
      nextScreen = const AdminIstoricScreen();
    } else if (index == 3) {
      nextScreen = const AdminProfileScreen();
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

