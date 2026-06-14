import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gazprof/core/constants.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- WIDGETS ---
import 'package:gazprof/widgets/profile_avatar.dart';

// --- SHELL ---
import 'package:gazprof/screens/dispecer/dispecer_shell.dart';

// --- INTERNAL COMPONENTS ---
import 'dispecer_documente_empty.dart';
import 'dispecer_documente_list.dart';

class DispecerDocumenteScreen extends StatefulWidget {
  const DispecerDocumenteScreen({super.key});

  @override
  State<DispecerDocumenteScreen> createState() => _DispecerDocumenteScreenState();
}

class _DispecerDocumenteScreenState extends State<DispecerDocumenteScreen> with WidgetsBindingObserver {

  late DateTime _startOfShift;
  late DateTime _endOfShift;
  late bool _inProgram;
  late Stream<QuerySnapshot> _ordersStream;

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
        _ordersStream = FirebaseFirestore.instance
            .collection(FirestoreCollections.orders)
            .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
            .where('data_creare', isLessThan: _endOfShift)
            .orderBy('data_creare', descending: true)
            .snapshots();
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

    _ordersStream = FirebaseFirestore.instance
        .collection(FirestoreCollections.orders)
        .where('data_creare', isGreaterThanOrEqualTo: _startOfShift)
        .where('data_creare', isLessThan: _endOfShift)
        .orderBy('data_creare', descending: true)
        .snapshots();
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
                // --- HEADER ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Monitorizare comenzi",
                        style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: ProfileAvatar(name: userProvider.userName, color: theme.brandBlue),
                      ),
                    ],
                  ),
                ),

                // --- DYNAMIC RANGE  ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _ordersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: theme.brandBlue));
                      }

                      final comenzi = snapshot.data?.docs ?? [];

                      if (!_inProgram || comenzi.isEmpty) {
                        return const DispecerDocumenteEmpty();
                      }

                      return DispecerDocumenteList(comenzi: comenzi);
                    },
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }

  // --- HELPERS UI  ---

  void _navigate(BuildContext context, int index) {
    DispecerShellState.of(context)?.switchTab(index);
  }

}

