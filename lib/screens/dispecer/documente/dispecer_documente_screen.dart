import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gazprof/core/constants.dart';

// --- THEME & PROVIDERS ---
import '../../../../core/theme_provider.dart';
import '../../../../core/user_provider.dart';

// --- WIDGETS ---
import 'package:gazprof/widgets/app_nav_bar.dart';
import 'package:gazprof/widgets/profile_avatar.dart';

// --- SCREENS ---
import '../home/dispecer_home_screen.dart';
import '../profile/dispecer_profile_screen.dart';
import 'package:gazprof/screens/dispecer/istoric/dispecer_istoric_screen.dart';

// --- INTERNAL COMPONENTS ---
import 'dispecer_documente_empty.dart';
import 'dispecer_documente_list.dart';

class DispecerDocumenteScreen extends StatefulWidget {
  const DispecerDocumenteScreen({super.key});

  @override
  State<DispecerDocumenteScreen> createState() => _DispecerDocumenteScreenState();
}

class _DispecerDocumenteScreenState extends State<DispecerDocumenteScreen> {

  // -- MODIFY THIS TO TEST ---
  bool _esteInProgram() {
    final now = DateTime.now();
    final startOfShift = DateTime(now.year, now.month, now.day, 7, 0, 0);
    final endOfShift = DateTime(now.year, now.month, now.day + 1, 1, 0, 0);
    return now.isAfter(startOfShift) && now.isBefore(endOfShift);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: theme.isDark ? Brightness.light : Brightness.dark,
    ));

    // --- DEFINING THE TIME RANGE FOR ORDERS  ---
    final now = DateTime.now();
    final startOfShift = DateTime(now.year, now.month, now.day, 7, 0, 0);
    final endOfShift = DateTime(now.year, now.month, now.day + 1, 1, 0, 0);

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
                    stream: FirebaseFirestore.instance
                        .collection(FirestoreCollections.orders)
                    // 1. Filter to be >= today at hour 07:00
                        .where('data_creare', isGreaterThanOrEqualTo: startOfShift)
                    // 2. Filter to be < tomorrow at hour 01:00
                        .where('data_creare', isLessThan: endOfShift)
                    // 3. We order from the new to the oldest
                        .orderBy('data_creare', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: theme.brandBlue));
                      }

                      final comenzi = snapshot.data?.docs ?? [];
                      final inProgram = _esteInProgram();

                      if (!inProgram || comenzi.isEmpty) {
                        return const DispecerDocumenteEmpty();
                      }

                      return DispecerDocumenteList(comenzi: comenzi);
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- NAVBAR ---
          AppNavBar(
            selectedIndex: 1,
            onTab: (i) => _navigate(context, i),
            navBarBg: theme.navBarBg,
            navIconUnselected: theme.navIconUnselected,
            brandBlue: theme.brandBlue,
          ),
        ],
      ),
    );
  }

  // --- HELPERS UI  ---

  void _navigate(BuildContext context, int index) {
    if (index == 1) return;

    Widget nextScreen;
    if (index == 0) {
      nextScreen = const DispecerHomeScreen();
    } else if (index == 2) {
      nextScreen = const DispecerIstoricScreen();
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

