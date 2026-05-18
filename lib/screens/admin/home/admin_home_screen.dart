import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gazprof/screens/admin/istoric/admin_istoric_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- COMPONENTS ---
import 'package:gazprof/widgets/nav_bar_clipper.dart';
import 'admin_home_preluate_list.dart';
import 'admin_home_live_list.dart';
import 'admin_home_users_list.dart';
import 'package:gazprof/screens/admin/documente/admin_documente_screen.dart';
import 'package:gazprof/screens/admin/profile/admin_profile_screen.dart';
import 'package:gazprof/screens/admin/profile/admin_gestionare_screen.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // --- GETTERS FOR CURRENT SHIF
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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

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
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: _buildProfileCircle(userProvider.userName, theme),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildRealStatsRow(theme),
                        const SizedBox(height: 20),

                        _buildAdminActionButtons(theme),
                        const SizedBox(height: 25),

                        _buildComenziStream(theme),
                        const SizedBox(height: 10),

                        _buildSectionHeader("UTILIZATORI", theme),
                        const AdminHomeUsersList(),

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
            child: _buildCustomNavBar(context, theme, 0),
          ),
        ],
      ),
    );
  }

  // --- STATS ---
  Widget _buildRealStatsRow(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comenzi')
                  .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
                  .where('data_creare', isLessThan: _endOfShift)
                  .snapshots(),
              builder: (context, snapshot) {
                int totalAzi = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildStatCard(totalAzi.toString(), "Comenzi azi", const Color(0xFFFF6B00), theme);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                int totalUsers = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildStatCard(totalUsers.toString(), "Utilizatori", theme.brandBlue, theme);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comenzi')
                  .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
                  .where('data_creare', isLessThan: _endOfShift)
                  .where('status', isEqualTo: 'Finalizata')
                  .snapshots(),
              builder: (context, snapshot) {
                int livrate = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return _buildStatCard(livrate.toString(), "Livrate", const Color(0xFF0C9E43), theme);
              },
            ),
          ),
        ],
      ),
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

  // --- BTN Atribuie rol & Creaza Comanda ---
  Widget _buildAdminActionButtons(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminGestionareScreen()),
                );
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.brandBlue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, color: theme.brandBlue, size: 18),
                        const SizedBox(width: 6),
                        Text("Atribuie roluri", style: TextStyle(color: theme.brandBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigate(context, 1),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_box_outlined, color: Color(0xFFFF6B00), size: 18),
                        const SizedBox(width: 6),
                        const Text("Creare comandă", style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComenziStream(ThemeProvider theme) {
    final currentAdminId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comenzi')
          .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
          .where('data_creare', isLessThan: _endOfShift)
          .orderBy('data_creare', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.brandBlue));
        }

        final docs = snapshot.data!.docs;

        final comenziPreluate = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Alocata' && data['id_sofer'] == currentAdminId;
        }).toList();

        final comenziLive = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'Alocata' && data['id_sofer'] == currentAdminId) return false;
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (comenziPreluate.isNotEmpty) ...[
              _buildSectionHeader("COMENZI PRELUATE", theme),
              AdminHomePreluateList(comenzi: comenziPreluate),
              const SizedBox(height: 15),
            ],

            _buildSectionHeader("COMENZI LIVE", theme),
            if (comenziLive.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text("Nu există comenzi live pentru ziua curentă.", style: TextStyle(color: theme.textSecondary, fontSize: 13)),
              )
            else
              AdminHomeLiveList(comenzi: comenziLive),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12, top: 10),
      child: Text(title, style: TextStyle(color: theme.textGriFix, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    );
  }

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
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // --- NAVIGATE LOGIC ---
  void _navigate(BuildContext context, int index) {
    if (index == 0) return;

    Widget nextScreen;
    if (index == 1) {
      nextScreen = const AdminDocumenteScreen();
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

