import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- SCREENS ---
import '../home/sofer_home_screen.dart';
import '../istoric/sofer_istoric_screen.dart';
import '../profile/sofer_profile_screen.dart';

// --- DETAILS SCREEN ---
import 'sofer_order_details_screen.dart';

class SoferDocumenteScreen extends StatelessWidget {
  const SoferDocumenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            theme.isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Comenzi alocate",
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildProfileCircle(
                        userProvider.userName,
                        theme,
                      ),
                    ],
                  ),
                ),

                Divider(
                  color:
                      theme.isDark
                          ? Colors.white10
                          : Colors.black12,
                  height: 1,
                ),

                Expanded(
                  child: _buildOrdersList(
                    context,
                    theme,
                  ),
                ),

                const SizedBox(height: 85),
              ],
            ),
          ),

          Positioned(
            bottom: 5 + bottomSafePadding,
            left: 18,
            right: 18,
            child: _buildCustomNavBar(
              context,
              theme,
              1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    ThemeProvider theme,
  ) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('comenzi')
              .where('id_sofer', isEqualTo: uid)
              .where('status', isEqualTo: 'Alocata')
              .orderBy('data_creare', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Eroare la încărcare'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "Nicio comandă activă",
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildOrderCard(context, docs[index].id, data, theme);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
    ThemeProvider theme,
  ) {
    List produse = data['produse'] ?? [];
    String mentiuni = data['mentiuni'] ?? "";
    Timestamp? ts = data['data_creare'];
    DateTime date = ts?.toDate() ?? DateTime.now();
    String formattedTime = DateFormat('HH:mm').format(date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SoferOrderDetailsScreen(
                  orderId: orderId,
                  orderData: data,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardCreateCommand,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.cardOutline),
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
                        data['adresa_livrare'] ?? 'Adresă necunoscută',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        data['telefon_client'] ?? '-', // ELIMINAT "Oradea"
                        style: TextStyle(color: theme.textGriFix, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.brandBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Alocată",
                    style: TextStyle(
                      color: theme.brandBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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
                          color: theme.brandBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${item['cantitate']}x",
                          style: TextStyle(
                            color: theme.brandBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
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
                  color: theme.isDark ? Colors.white.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
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
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 25, color: Colors.black12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Azi $formattedTime",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: theme.textPrimary, fontSize: 13),
                    children: [
                      const TextSpan(text: "Total: "),
                      TextSpan(
                        text: "${data['total_comanda'] ?? 0} lei",
                        style: const TextStyle(
                          color: Color(0xFFFF6B00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCircle(
    String name,
    ThemeProvider theme,
  ) {
    String initials = "U";
    if (name.isNotEmpty) {
      List<String> words = name.trim().split(RegExp(r'\s+'));
      initials = words.length > 1
              ? (words[0][0] + words[1][0]).toUpperCase()
              : words[0][0].toUpperCase();
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.brandBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavBar(
    BuildContext context,
    ThemeProvider theme,
    int selectedIndex,
  ) {
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
            clipper: _NavBarClipper(
              buttonLeft: btnLeft,
              buttonBottom: btnBottom,
              buttonSize: btnSize,
              margin: 4.0,
            ),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: theme.navBarBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(4, (index) {
                  if (index == selectedIndex) {
                    return const Expanded(child: SizedBox());
                  }
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _navigate(context, index),
                      child: Center(
                        child: SvgPicture.asset(
                          navItems[index]['path'],
                          width: navItems[index]['inactiveSize'],
                          height: navItems[index]['inactiveSize'],
                          colorFilter: ColorFilter.mode(
                            theme.navIconUnselected,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            left: btnLeft,
            bottom: btnBottom,
            child: Container(
              width: btnSize,
              height: btnSize,
              decoration: BoxDecoration(
                color: theme.brandBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  navItems[selectedIndex]['path'],
                  width: navItems[selectedIndex]['activeSize'],
                  height: navItems[selectedIndex]['activeSize'],
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == 1) return;
    Widget nextScreen;
    if (index == 0) {
      nextScreen = const SoferHomeScreen();
    } else if (index == 2) {
      nextScreen = const SoferIstoricScreen();
    } else {
      nextScreen = const SoferProfileScreen();
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
  final double buttonLeft, buttonBottom, buttonSize, margin;
  _NavBarClipper({
    required this.buttonLeft,
    required this.buttonBottom,
    required this.buttonSize,
    required this.margin,
  });

  @override
  Path getClip(Size size) {
    Path barPath = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(24)));
    double centerX = buttonLeft + (buttonSize / 2);
    double centerY = size.height - (buttonBottom + (buttonSize / 2));
    Path holePath = Path()..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: (buttonSize / 2) + margin));
    return Path.combine(PathOperation.difference, barPath, holePath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}