import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gazprof/core/constants.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- SCREENS & COMPONENTS ---
import 'package:gazprof/widgets/app_nav_bar.dart';
import 'package:gazprof/widgets/profile_avatar.dart';
import '../documente/sofer_documente_screen.dart';
import '../istoric/sofer_istoric_screen.dart';
import '../profile/sofer_profile_screen.dart';
import 'sofer_create_order_screen.dart';
import 'sofer_home_list.dart';
import 'sofer_home_empty.dart';

class SoferHomeScreen extends StatefulWidget {
  const SoferHomeScreen({super.key});

  @override
  State<SoferHomeScreen> createState() => _SoferHomeScreenState();
}

class _SoferHomeScreenState extends State<SoferHomeScreen> {
  String _filterType = AppConstants.addressTypeCity;

  // --- GETTERS FOR CURRENT SHIFT
  DateTime get _startOfShift {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 7, 0, 0);
  }

  DateTime get _endOfShift {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 1, 0, 0);
  }

  bool _esteInProgram() {
    final now = DateTime.now();
    return now.isAfter(_startOfShift) && now.isBefore(_endOfShift);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);


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
                // --- HEADER  ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/logo_gazprof.png', height: 22),
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: ProfileAvatar(name: userProvider.userName, color: theme.brandBlue),
                      ),
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
                            TextSpan(text: userProvider.userRole, style: TextStyle(color: theme.roleSofer)),
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
                        const SizedBox(height: 20),

                        // Show the rapid order creation btn only if the driver is in the schedule
                        if (inProgram) ...[
                          _buildQuickOrderButton(context),
                          const SizedBox(height: 25),
                        ],

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

          // --- NAVBAR ---
          AppNavBar(
            selectedIndex: 0,
            onTab: (i) => _navigate(context, i),
            navBarBg: theme.navBarBg,
            navIconUnselected: theme.navIconUnselected,
            brandBlue: theme.brandBlue,
          ),
        ],
      ),
    );
  }

  // --- WIDGET DYNAMIC ZONE ( EMPTY OR LIST )
  Widget _buildDynamicContent(ThemeProvider theme, bool inProgram) {
    if (!inProgram) {
      return const SoferHomeEmpty(
        titlu: "În afara programului",
        mesaj: "Te afli în afara programului de lucru\n(07:00 - 24:00).\nPreluarea și crearea comenzilor sunt dezactivate.",
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.orders)
          .where('status', isEqualTo: OrderStatus.waiting.label)
          .where('tip_adresa', isEqualTo: _filterType)
          .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
          .where('data_creare', isLessThan: _endOfShift)
          .orderBy('data_creare', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SoferHomeEmpty(titlu: "Eroare", mesaj: "A apărut o problemă la încărcarea comenzilor.");
        }

        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Center(child: CircularProgressIndicator(color: theme.brandBlue)),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          // Dynamic message
          String tipComanda = _filterType == AppConstants.addressTypeCity ? 'Oraș' : 'Rute';

          return SoferHomeEmpty(
            titlu: "Ești online",
            mesaj: "Nu există comenzi de tip $tipComanda în așteptare pentru tura curentă.",
          );
        }

        return SoferHomeList(comenzi: docs);
      },
    );
  }

  // --- STATS ---
  Widget _buildRealStatsRow(ThemeProvider theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.orders)
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

            if (status == OrderStatus.waiting.label) disponibile++;
            if (status == OrderStatus.allocated.label && idSofer == uid) preluate++;
            if (status == OrderStatus.completed.label && idSofer == uid) livrate++;
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

  // --- BTN CREATE FAST ORDER
  Widget _buildQuickOrderButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SoferCreateOrderScreen())),
        child: Container(
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFFFF6B00), borderRadius: BorderRadius.circular(25)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Comandă rapidă", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
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
            "COMENZI DISPONIBILE",
            style: TextStyle(color: theme.textGriFix, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildFilterTab("Oraș", "oras", theme),
              const SizedBox(width: 10),
              _buildFilterTab("Rute", "rute", theme),
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



  void _navigate(BuildContext context, int index) {
    if (index == 0) return;
    Widget nextScreen;
    if (index == 1) nextScreen = const SoferDocumenteScreen();
    else if (index == 2) nextScreen = const SoferIstoricScreen();
    else nextScreen = const SoferProfileScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(pageBuilder: (context, a1, a2) => nextScreen, transitionDuration: Duration.zero),
    );
  }
}

