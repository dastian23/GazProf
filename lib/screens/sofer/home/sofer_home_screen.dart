import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- SCREENS ---
import '../documente/sofer_documente_screen.dart';
import '../istoric/sofer_istoric_screen.dart';
import '../profile/sofer_profile_screen.dart';
import 'sofer_create_order_screen.dart';

class SoferHomeScreen extends StatefulWidget {
  const SoferHomeScreen({super.key});

  @override
  State<SoferHomeScreen> createState() => _SoferHomeScreenState();
}

class _SoferHomeScreenState extends State<SoferHomeScreen> {
  String _filterType = 'intern';

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // HEADER & LOGO
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/logo_gazprof.png',
                        height: 22,
                      ),
                      _buildProfileCircle(
                        userProvider.userName,
                        theme,
                      ),
                    ],
                  ),
                ),

                // WELCOME BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bun venit,",
                        style: TextStyle(
                          color: theme.textGriFix,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(text: userProvider.userName),
                            const TextSpan(
                              text: " - ",
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                             TextSpan(
                              text: userProvider.userRole,
                              style: TextStyle(
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Divider(
                        color: theme.isDark
                            ? Colors.white10
                            : Colors.black12,
                        height: 1,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildRealStatsRow(theme),
                        const SizedBox(height: 20),
                        _buildQuickOrderButton(context),
                        const SizedBox(height: 25),
                        _buildSectionHeader(theme),
                        _buildOrdersList(theme),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 5 + bottomSafePadding,
            left: 18,
            right: 18,
            child: _buildCustomNavBar(context, theme, 0),
          ),
        ],
      ),
    );
  }

  Widget _buildRealStatsRow(ThemeProvider theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comenzi')
          .snapshots(),
      builder: (context, snapshot) {
        int disponibile = 0;
        int preluate = 0;
        int livrate = 0;

        if (snapshot.hasData) {
          final uid = FirebaseAuth.instance.currentUser?.uid;

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            String status = data['status'] ?? '';
            String? idSofer = data['id_sofer'];

            if (status == 'In asteptare') {
              disponibile++;
            }

            if (status == 'Alocata' && idSofer == uid) {
              preluate++;
            }

            if (status == 'Finalizata' && idSofer == uid) {
              livrate++;
            }
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard(
              disponibile.toString(),
              "Disponibile",
              const Color(0xFFFF6B00),
              theme,
            ),
            _buildStatCard(
              preluate.toString(),
              "Preluate",
              theme.brandBlue,
              theme,
            ),
            _buildStatCard(
              livrate.toString(),
              "Livrate",
              const Color(0xFF0C9E43),
              theme,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String val,
    String label,
    Color color,
    ThemeProvider theme,
  ) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardCreateCommand,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.cardOutline,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOrderButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SoferCreateOrderScreen(),
            ),
          );
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Comandă rapidă",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "COMENZI DISPONIBILE",
            style: TextStyle(
              color: theme.textGriFix,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              _buildFilterTab("Intern", "intern", theme),
              const SizedBox(width: 10),
              _buildFilterTab("Extern", "extern", theme),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    String label,
    String type,
    ThemeProvider theme,
  ) {
    bool isSelected = _filterType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.brandBlue
              : (theme.isDark
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : theme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(ThemeProvider theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comenzi')
          .where('status', isEqualTo: 'In asteptare')
          .where('tip_adresa', isEqualTo: _filterType)
          .orderBy('data_creare', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Eroare: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "Nu există comenzi disponibile",
              style: TextStyle(
                color: theme.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(
              docs[index],
              theme,
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(DocumentSnapshot doc, ThemeProvider theme) {
    final data = doc.data() as Map<String, dynamic>;
    Timestamp? ts = data['data_creare'];
    DateTime date = ts?.toDate() ?? DateTime.now();
    String formattedTime = DateFormat('HH:mm').format(date);
    
    List produse = data['produse'] ?? [];
    String mentiuni = data['mentiuni'] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardCreateCommand,
        borderRadius: BorderRadius.circular(18),
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
                        fontWeight: FontWeight.bold, 
                        fontSize: 14
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data['telefon_client'] ?? '-', 
                      style: TextStyle(color: theme.textGriFix, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "In asteptare",
                  style: TextStyle(
                    color: Color(0xFFFF6B00), 
                    fontSize: 11, 
                    fontWeight: FontWeight.bold
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
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.orange.withOpacity(0.05),
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
                        fontStyle: FontStyle.italic
                      ),
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
              Text(
                "Azi $formattedTime",
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
                      text: "${data['total_comanda'] ?? 0} lei",
                      style: const TextStyle(
                        color: Color(0xFFFF6B00), 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
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
              child: Text(
                "Preia comanda",
                style: TextStyle(
                  color: theme.textPrimary, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 13
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takeOrder(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('comenzi')
          .doc(id)
          .update({
        'status': 'Alocata',
        'id_sofer':
            FirebaseAuth.instance.currentUser?.uid,
        'data_preluare':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Eroare alocare comandă: $e');
    }
  }

  Widget _buildProfileCircle(
    String name,
    ThemeProvider theme,
  ) {
    String initials = "U";

    if (name.trim().isNotEmpty) {
      initials = name
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .map((e) => e[0])
          .join()
          .toUpperCase();
    }

    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: theme.brandBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
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
    double screenWidth =
        MediaQuery.of(context).size.width - 36;

    double tabWidth = screenWidth / 4;

    const double btnSize = 52.0;

    double btnLeft =
        (tabWidth * selectedIndex) +
        (tabWidth / 2) -
        (btnSize / 2);

    const double btnBottom = 12.0;

    List<Map<String, dynamic>> navItems = [
      {
        'path': 'assets/home.svg',
        'inactiveSize': 24.0,
        'activeSize': 22.0,
      },
      {
        'path': 'assets/file.svg',
        'inactiveSize': 29.0,
        'activeSize': 22.0,
      },
      {
        'path': 'assets/time.svg',
        'inactiveSize': 33.0,
        'activeSize': 24.0,
      },
      {
        'path': 'assets/user.svg',
        'inactiveSize': 24.5,
        'activeSize': 22.0,
      },
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
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(4, (index) {
                  if (index == selectedIndex) {
                    return const Expanded(
                      child: SizedBox(),
                    );
                  }

                  return Expanded(
                    child: GestureDetector(
                      behavior:
                          HitTestBehavior.opaque,
                      onTap: () =>
                          _navigate(context, index),
                      child: Center(
                        child: SvgPicture.asset(
                          navItems[index]['path'],
                          width: navItems[index]
                              ['inactiveSize'],
                          height: navItems[index]
                              ['inactiveSize'],
                          colorFilter:
                              ColorFilter.mode(
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
                  width: navItems[selectedIndex]
                      ['activeSize'],
                  height: navItems[selectedIndex]
                      ['activeSize'],
                  colorFilter:
                      const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
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
      nextScreen = const SoferDocumenteScreen();
    } else if (index == 2) {
      nextScreen = const SoferIstoricScreen();
    } else {
      nextScreen = const SoferProfileScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => nextScreen,
        transitionDuration: Duration.zero,
      ),
    );
  }
}

class _NavBarClipper extends CustomClipper<Path> {
  final double buttonLeft;
  final double buttonBottom;
  final double buttonSize;
  final double margin;

  _NavBarClipper({
    required this.buttonLeft,
    required this.buttonBottom,
    required this.buttonSize,
    required this.margin,
  });

  @override
  Path getClip(Size size) {
    Path basePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            0,
            size.width,
            size.height,
          ),
          const Radius.circular(24),
        ),
      );

    Path cutoutPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            buttonLeft + buttonSize / 2,
            size.height -
                (buttonBottom + buttonSize / 2),
          ),
          radius: buttonSize / 2 + margin,
        ),
      );

    return Path.combine(
      PathOperation.difference,
      basePath,
      cutoutPath,
    );
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) {
    return true;
  }
}