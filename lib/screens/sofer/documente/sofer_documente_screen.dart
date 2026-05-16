import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- SCREENS & COMPONENTS ---
import '../home/sofer_home_screen.dart';
import '../istoric/sofer_istoric_screen.dart';
import '../profile/sofer_profile_screen.dart';
import 'sofer_documente_list.dart';
import 'sofer_documente_empty.dart';

class SoferDocumenteScreen extends StatefulWidget {
  const SoferDocumenteScreen({super.key});

  @override
  State<SoferDocumenteScreen> createState() => _SoferDocumenteScreenState();
}

class _SoferDocumenteScreenState extends State<SoferDocumenteScreen> {
  String _filterType = 'intern';

  // --- GETTERS FOR CURRENT SHIFT
  // The real value will be 6,0,0 - now we use 0,0,0 to test
  DateTime get _startOfShift {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 0, 0, 0);
  }

  // The real value will be 18,0,0 - now we use 23, 59, 59 to test
  DateTime get _endOfShift {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  bool _esteInProgram() {
    // Uncomment this to have the real logic and delete that return
    // final now = DateTime.now();
    // return now.isAfter(_startOfShift) && now.isBefore(_endOfShift);

    // Delete this
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    final bool inProgram = _esteInProgram();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: theme.scaffoldBg,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // --- HEADER & LOGO ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/logo_gazprof.png', height: 22),
                      _buildProfileCircle(userProvider.userName, theme),
                    ],
                  ),
                ),

                // --- WELCOME BAR ---
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
                            TextSpan(text: userProvider.userRole, style: const TextStyle(color: Color(0xFFFF6B00))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Divider(color: theme.isDark ? Colors.white10 : Colors.black12, height: 1),
                    ],
                  ),
                ),

                // --- BODY CONTENT ---
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildRealStatsRow(theme),
                        const SizedBox(height: 25),

                        _buildSectionHeader(theme),

                        // DYNAMIC ZONE
                        _buildDynamicContent(theme, inProgram),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- NAVBAR  ---
          Positioned(
            bottom: 5 + bottomSafePadding,
            left: 18, right: 18,
            child: _buildCustomNavBar(context, theme, 1),
          ),
        ],
      ),
    );
  }

  // --- DYNAMIC ZONE ---
  Widget _buildDynamicContent(ThemeProvider theme, bool inProgram) {
    if (!inProgram) {
      return const SoferDocumenteEmpty(
        titlu: "În afara programului",
        mesaj: "Te afli în afara programului de lucru\n(06:00 - 18:00).\nNu poți vizualiza comenzile alocate.",
      );
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comenzi')
          .where('status', isEqualTo: 'Alocata')
          .where('id_sofer', isEqualTo: currentUserId)
          .where('tip_adresa', isEqualTo: _filterType)
          .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
          .where('data_creare', isLessThan: _endOfShift)
          .orderBy('data_creare', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SoferDocumenteEmpty(titlu: "Eroare", mesaj: "A apărut o problemă la încărcarea documentelor.");
        }

        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Center(child: CircularProgressIndicator(color: theme.brandBlue)),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          String tipComanda = _filterType == 'intern' ? 'Intern' : 'Extern';
          return SoferDocumenteEmpty(
            titlu: "Ești la zi!",
            mesaj: "Nu ai nicio comandă $tipComanda alocată ție în așteptare.\nMergi la panoul principal pentru a prelua comenzi noi.",
          );
        }

        return SoferDocumenteList(comenzi: docs);
      },
    );
  }

  // --- STATS ---
  Widget _buildRealStatsRow(ThemeProvider theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comenzi')
          .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
          .where('data_creare', isLessThan: _endOfShift)
          .snapshots(),
      builder: (context, snapshot) {
        int disponibile = 0, preluate = 0, livrate = 0;

        if (snapshot.hasData) {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? '';
            String? idSofer = data['id_sofer'];

            if (status == 'In asteptare') disponibile++;
            if (status == 'Alocata' && idSofer == uid) preluate++;
            if (status == 'Finalizata' && idSofer == uid) livrate++;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _buildStatCard(disponibile.toString(), "Disponibile", const Color(0xFFFF6B00), theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(preluate.toString(), "Preluate", theme.brandBlue, theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(livrate.toString(), "Livrate", const Color(0xFF0C9E43), theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String val, String label, Color color, ThemeProvider theme) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.cardOutline, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // --- FILTER SECTION ---
  Widget _buildSectionHeader(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "COMENZI PRELUATE",
            style: TextStyle(color: theme.textGriFix, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
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

  Widget _buildFilterTab(String label, String type, ThemeProvider theme) {
    bool isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.brandBlue : (theme.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : theme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- HELPERS  ---
  Widget _buildProfileCircle(String name, ThemeProvider theme) {
    String initials = "U";
    if (name.trim().isNotEmpty) {
      initials = name.trim().split(RegExp(r'\s+')).take(2).map((e) => e[0]).join().toUpperCase();
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
    if (index == 0) nextScreen = const SoferHomeScreen();
    else if (index == 2) nextScreen = const SoferIstoricScreen();
    else nextScreen = const SoferProfileScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(pageBuilder: (context, a1, a2) => nextScreen, transitionDuration: Duration.zero),
    );
  }
}

class _NavBarClipper extends CustomClipper<Path> {
  final double buttonLeft, buttonBottom, buttonSize, margin;

  _NavBarClipper(
      {required this.buttonLeft, required this.buttonBottom, required this.buttonSize, required this.margin});

  @override
  Path getClip(Size size) {
    Path basePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(24)));
    Path cutoutPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(buttonLeft + buttonSize / 2,
          size.height - (buttonBottom + buttonSize / 2)),
          radius: buttonSize / 2 + margin));
    return Path.combine(PathOperation.difference, basePath, cutoutPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}