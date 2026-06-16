import 'dart:async';
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
import 'package:gazprof/widgets/profile_avatar.dart';
import 'package:gazprof/screens/sofer/sofer_shell.dart';
import 'sofer_documente_list.dart';
import 'sofer_documente_empty.dart';

class SoferDocumenteScreen extends StatefulWidget {
  const SoferDocumenteScreen({super.key});

  @override
  State<SoferDocumenteScreen> createState() => _SoferDocumenteScreenState();
}

class _SoferDocumenteScreenState extends State<SoferDocumenteScreen> with WidgetsBindingObserver {
  String _filterType = AppConstants.addressTypeCity;

  late DateTime _startOfShift;
  late DateTime _endOfShift;
  late bool _inProgram;
  Stream<QuerySnapshot>? _allShiftOrdersStream;

  Timer? _shiftTimer;

  void _recomputeShift() {
    final now = DateTime.now();
    final hour = now.hour;

    DateTime newStart;
    DateTime newEnd;
    bool newInProgram;

    if (hour < 1) {
      final prevDay = now.subtract(const Duration(days: 1));
      newStart = DateTime(prevDay.year, prevDay.month, prevDay.day, 7, 0, 0);
      newEnd = DateTime(now.year, now.month, now.day, 1, 0, 0);
      newInProgram = now.isAfter(newStart) && now.isBefore(newEnd);
    } else if (hour < 7) {
      newStart = DateTime(now.year, now.month, now.day, 7, 0, 0);
      newEnd = DateTime(now.year, now.month, now.day + 1, 1, 0, 0);
      newInProgram = false;
    } else {
      newStart = DateTime(now.year, now.month, now.day, 7, 0, 0);
      newEnd = DateTime(now.year, now.month, now.day + 1, 1, 0, 0);
      newInProgram = now.isAfter(newStart) && now.isBefore(newEnd);
    }

    if (newStart != _startOfShift || newEnd != _endOfShift || newInProgram != _inProgram) {
      setState(() {
        _startOfShift = newStart;
        _endOfShift = newEnd;
        _inProgram = newInProgram;
        _allShiftOrdersStream = newInProgram
            ? FirebaseFirestore.instance
                .collection(FirestoreCollections.orders)
                .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
                .where('data_creare', isLessThan: _endOfShift)
                .orderBy('data_creare', descending: true)
                .snapshots()
            : null;
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
    _inProgram = false;
    _recomputeShift();
    _shiftTimer = Timer.periodic(const Duration(seconds: 30), (_) => _recomputeShift());
  }

  @override
  void dispose() {
    _shiftTimer?.cancel();
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
                      Text(
                        "Comenzi preluate",
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: ProfileAvatar(name: userProvider.userName, color: theme.brandBlue),
                      ),
                    ],
                  ),
                ),

                // --- BODY CONTENT ---
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildRealStatsRow(theme),
                        const SizedBox(height: 25),

                        _buildSectionHeader(theme),

                        // DYNAMIC ZONE
                        _buildDynamicContent(theme),

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

  // --- DYNAMIC ZONE: uses the shared stream, filters locally ---
  Widget _buildDynamicContent(ThemeProvider theme) {
    if (!_inProgram) {
      return const SoferDocumenteEmpty(
        titlu: "În afara programului",
        mesaj: "Te afli în afara programului de lucru\n(07:00 - 24:00).\nNu poți vizualiza comenzile alocate.",
      );
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _allShiftOrdersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SoferDocumenteEmpty(titlu: "Eroare", mesaj: "A apărut o problemă la încărcarea documentelor.");
        }

        final allDocs = snapshot.data?.docs ?? [];

        // Filter locally: allocated + my ID + current tab type
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == OrderStatus.allocated.label &&
              data['id_sofer'] == currentUserId &&
              data['tip_adresa'] == _filterType;
        }).toList();

        if (docs.isEmpty && snapshot.hasData) {
          String tipComanda = _filterType == AppConstants.addressTypeCity ? 'Oraș' : 'Rute';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 60),
              SoferDocumenteEmpty(
                titlu: "Ești la zi!",
                mesaj: "Nu ai nicio comandă $tipComanda alocată ție în așteptare.\nMergi la panoul principal pentru a prelua comenzi noi.",
              ),
            ],
          );
        }

        return SoferDocumenteList(comenzi: docs);
      },
    );
  }

  // --- STATS: reuses the shared stream ---
  Widget _buildRealStatsRow(ThemeProvider theme) {
    if (!_inProgram) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: _buildStatCard("0", "Disponibile", const Color(0xFFFF6B00), theme)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard("0", "Preluate", theme.brandBlue, theme)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard("0", "Livrate", const Color(0xFF0C9E43), theme)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _allShiftOrdersStream,
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

  // --- HELPERS  ---

  void _navigate(BuildContext context, int index) {
    SoferShellState.of(context)?.switchTab(index);
  }
}

