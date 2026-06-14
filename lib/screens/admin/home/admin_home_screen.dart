import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gazprof/core/constants.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- WIDGETS ---
import 'package:gazprof/widgets/profile_avatar.dart';

// --- SHELL ---
import 'package:gazprof/screens/admin/admin_shell.dart';

// --- COMPONENTS ---
import 'admin_home_preluate_list.dart';
import 'admin_home_live_list.dart';
import 'admin_home_users_list.dart';
import 'package:gazprof/screens/admin/profile/admin_gestionare_screen.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with WidgetsBindingObserver {
  late DateTime _startOfShift;
  late DateTime _endOfShift;

  void _recomputeShift() {
    final now = DateTime.now();
    final newStart = DateTime(now.year, now.month, now.day, 7, 0, 0);
    final newEnd = DateTime(now.year, now.month, now.day + 1, 1, 0, 0);
    if (newStart != _startOfShift || newEnd != _endOfShift) {
      setState(() {
        _startOfShift = newStart;
        _endOfShift = newEnd;
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recomputeShift();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

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


        ],
      ),
    );
  }

  // --- STATS ---
  Widget _buildStatsRow(int totalAzi, int livrate, ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(totalAzi.toString(), "Comenzi azi", const Color(0xFFFF6B00), theme)),
          const SizedBox(width: 8),
          Expanded(
            child: FutureBuilder<AggregateQuerySnapshot>(
              future: FirebaseFirestore.instance.collection(FirestoreCollections.users).count().get(),
              builder: (context, snapshot) {
                return _buildStatCard((snapshot.data?.count ?? 0).toString(), "Utilizatori", theme.brandBlue, theme);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard(livrate.toString(), "Livrate", const Color(0xFF0C9E43), theme)),
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
          .collection(FirestoreCollections.orders)
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
          return data['status'] == OrderStatus.allocated.label && data['id_sofer'] == currentAdminId;
        }).toList();

        final comenziLive = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == OrderStatus.allocated.label && data['id_sofer'] == currentAdminId) return false;
          return true;
        }).toList();

        final Map<String, String> liveDriverNames = {};
        final ids = docs.map((d) => (d.data() as Map<String, dynamic>)['id_sofer'] as String?).whereType<String>().toSet();
        for (final id in ids) {
          final name = driverNameCache[id];
          if (name != null) liveDriverNames[id] = name;
        }
        preloadDriverNames(ids);

        int totalAzi = docs.length;
        int livrate = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == OrderStatus.completed.label).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildStatsRow(totalAzi, livrate, theme),
            const SizedBox(height: 20),
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
              AdminHomeLiveList(comenzi: comenziLive, driverNames: liveDriverNames),
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




  // --- NAVIGATE LOGIC ---
  void _navigate(BuildContext context, int index) {
    AdminShellState.of(context)?.switchTab(index);
  }
}

