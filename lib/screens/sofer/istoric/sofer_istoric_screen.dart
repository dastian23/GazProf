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
import 'package:gazprof/screens/sofer/sofer_shell.dart';

// --- COMPONENTS  ---
import 'sofer_istoric_empty.dart';
import 'sofer_istoric_list.dart';

class SoferIstoricScreen extends StatefulWidget {
  const SoferIstoricScreen({super.key});

  @override
  State<SoferIstoricScreen> createState() => _SoferIstoricScreenState();
}

class _SoferIstoricScreenState extends State<SoferIstoricScreen> {
  String _typeFilter = 'Toate';

  // Current date & range
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );

  // --- CĂUTARE TEXT ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showPaymentStats = false;

  // --- FETCH: stream pentru azi, future pentru perioade trecute ---
  Stream<QuerySnapshot>? _istoricStream;
  Future<QuerySnapshot>? _istoricFuture;

  bool _isToday() {
    final now = DateTime.now();
    final s = _selectedDateRange.start;
    final e = _selectedDateRange.end;
    return s.year == now.year && s.month == now.month && s.day == now.day &&
           e.year == now.year && e.month == now.month && e.day == now.day;
  }

  void _onSearchSubmitted(String value) {
    setState(() => _searchQuery = value.toLowerCase().trim());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  void initState() {
    super.initState();
    _reloadIstoric();
  }

  void _reloadIstoric() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final start = DateTime(_selectedDateRange.start.year, _selectedDateRange.start.month, _selectedDateRange.start.day, 0, 0, 0);
    final end = DateTime(_selectedDateRange.end.year, _selectedDateRange.end.month, _selectedDateRange.end.day, 23, 59, 59);
    final query = FirebaseFirestore.instance
        .collection(FirestoreCollections.orders)
        .where('id_sofer', isEqualTo: currentUserId)
        .where('status', whereIn: [OrderStatus.completed.label, OrderStatus.cancelled.label])
        .where('data_creare', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('data_creare', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('data_creare', descending: true);

    setState(() {
      if (_isToday()) {
        _istoricStream = query.snapshots();
        _istoricFuture = null;
      } else {
        _istoricFuture = query.get();
        _istoricStream = null;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- MAIN BUTTON TEXT FORMATTER ---
  String _formatDateRange(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    const luni = ['Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      const zile = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];
      return "${zile[start.weekday - 1]}, ${start.day} ${luni[start.month - 1]} ${start.year}";
    } else if (start.year == end.year && start.month == end.month) {
      return "${start.day} - ${end.day} ${luni[start.month - 1]} ${start.year}";
    } else {
      return "${start.day} ${luni[start.month - 1]} - ${end.day} ${luni[end.month - 1]} ${start.year}";
    }
  }

  // --- 1. FAST MENU ---
  void _openDateMenu(BuildContext context, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 5, decoration: BoxDecoration(color: theme.isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text("Selectează perioada", style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Option 1: Custom Calendar
                  _buildMenuButton(Icons.date_range_rounded, "Alege din Calendar", "Zile mai multe, mai multe luni sau ani", true, () {
                    Navigator.pop(bottomSheetContext);
                    _openNativeCalendar(context, theme);
                  }, theme),

                  const SizedBox(height: 10),
                  Divider(color: theme.isDark ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 10),

                  // Option 2: Today
                  _buildMenuButton(Icons.today_rounded, "Astăzi", "Doar comenzile de azi", false, () {
                    _selectedDateRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
                    _reloadIstoric();
                    Navigator.pop(bottomSheetContext);
                  }, theme),

                  const SizedBox(height: 10),

                  // Option 3: Last Month
                  _buildMenuButton(Icons.calendar_view_month_rounded, "Luna curentă", "Toate comenzile din această lună", false, () {
                    final now = DateTime.now();
                    _selectedDateRange = DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 0));
                    _reloadIstoric();
                    Navigator.pop(bottomSheetContext);
                  }, theme),

                  const SizedBox(height: 10),

                  // Option 4: Last Year
                  _buildMenuButton(Icons.calendar_month_rounded, "Anul curent", "Toate comenzile de anul acesta", false, () {
                    final now = DateTime.now();
                    _selectedDateRange = DateTimeRange(start: DateTime(now.year, 1, 1), end: DateTime(now.year, 12, 31));
                    _reloadIstoric();
                    Navigator.pop(bottomSheetContext);
                  }, theme),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 2. THE NATIVE CALENDAR ---
  Future<void> _openNativeCalendar(BuildContext context, ThemeProvider theme) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      helpText: 'Selectează perioada dorită',
      cancelText: 'ANULEAZĂ',
      confirmText: 'APLICĂ',
      builder: (context, child) {
        return Theme(
          data: theme.isDark
              ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.brandBlue,
              onPrimary: Colors.white,
              surface: theme.scaffoldBg,
              onSurface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
          )
              : ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.brandBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            appBarTheme: const AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDateRange = picked;
      _reloadIstoric();
    }
  }

  // --- HELPER MENU BUTTON ---
  Widget _buildMenuButton(IconData icon, String title, String subtitle, bool isPrimary, VoidCallback onTap, ThemeProvider theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: isPrimary ? theme.brandBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isPrimary ? Border.all(color: theme.brandBlue.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isPrimary ? theme.brandBlue : theme.textSecondary, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isPrimary ? theme.brandBlue : theme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: theme.textSecondary, size: 14),
          ],
        ),
      ),
    );
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
      resizeToAvoidBottomInset: false,
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
                        "Istoric comenzi",
                        style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      GestureDetector(
                        onTap: () => _navigate(context, 3),
                        child: ProfileAvatar(name: userProvider.userName, color: theme.brandBlue),
                      ),
                    ],
                  ),
                ),

                // --- FIREBASE DINAMIC SPACE ---
                Expanded(
                  child: _istoricStream != null
                    ? StreamBuilder<QuerySnapshot>(
                        stream: _istoricStream,
                        builder: (context, snapshot) => _buildIstoricContent(context, snapshot, theme),
                      )
                    : FutureBuilder<QuerySnapshot>(
                        future: _istoricFuture,
                        builder: (context, snapshot) => _buildIstoricContent(context, snapshot, theme),
                      ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildIstoricContent(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot, ThemeProvider theme) {
    final isLoading = snapshot.connectionState == ConnectionState.waiting;
    final allIstoric = snapshot.data?.docs ?? [];

    final filteredComenzi = allIstoric.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (_typeFilter != 'Toate') {
        final tip = data['tip_adresa'] ?? AppConstants.addressTypeCity;
        if (tip.toString().toLowerCase() != _typeFilter.toLowerCase()) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final adresa = (data['adresa_livrare'] ?? '').toString().toLowerCase();
        final telefon = (data['telefon_client'] ?? '').toString();
        if (!adresa.contains(_searchQuery) && !telefon.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();

    double cardDiscountFromData(Map data) {
      final produse = data['produse'] as List? ?? [];
      double count = 0;
      for (var p in produse) {
        if (p['nume'].toString().startsWith('Butelie')) count += (p['cantitate'] ?? 0).toDouble();
      }
      return count * AppConstants.discountPerBottle;
    }
    int countAnulate = filteredComenzi.where((c) => (c.data() as Map)['status'] == OrderStatus.cancelled.label).length;
    int countCreate = filteredComenzi.length;
    double sumIncasati = 0, sumCash = 0, sumCard = 0, sumInvoice = 0;
    for (var doc in filteredComenzi) {
      final data = doc.data() as Map;
      if (data['status'] == OrderStatus.completed.label) {
        double total = (data['total_comanda'] ?? 0).toDouble();
        if (data['card_fidelitate'] == true) total -= cardDiscountFromData(data);
        sumIncasati += total;
        final tipPlata = (data['tip_plata'] ?? 'cash').toString();
        if (tipPlata == 'cash') { sumCash += total; }
        else if (tipPlata == 'card') { sumCard += total; }
        else if (tipPlata == 'factura') { sumInvoice += total; }
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showPaymentStats = !_showPaymentStats),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: theme.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: theme.brandBlue, size: 18),
                const SizedBox(width: 8),
                Text("Statistici", style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                AnimatedRotation(
                  turns: _showPaymentStats ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 8, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Status comenzi", style: TextStyle(color: theme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildStatBox(countAnulate.toString(), "Anulate", theme.statusTextAnulata, theme)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatBox(sumIncasati.toStringAsFixed(0), "Lei încasați", theme.statusTextFinalizata, theme)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatBox(countCreate.toString(), "Create", theme.brandBlue, theme)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Tip plată", style: TextStyle(color: theme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildStatBox(sumCash.toStringAsFixed(0), "Cash", const Color(0xFF4CAF50), theme)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatBox(sumCard.toStringAsFixed(0), "Card", const Color(0xFF2196F3), theme)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatBox(sumInvoice.toStringAsFixed(0), "Factura", const Color(0xFFFF9800), theme)),
                  ],
                ),
              ),
            ],
          ),
          crossFadeState: _showPaymentStats ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            maxLength: 200,
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
            onSubmitted: _onSearchSubmitted,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: theme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
              prefixIcon: GestureDetector(
                onTap: () => _onSearchSubmitted(_searchController.text),
                child: Icon(Icons.search_rounded, color: theme.textFieldIcon, size: 20),
              ),
              hintText: 'Caută după adresă sau telefon...',
              hintStyle: TextStyle(color: theme.textSecondary, fontSize: 14),
              counterText: '',
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(onTap: _clearSearch, child: Icon(Icons.clear, color: theme.textSecondary, size: 18))
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.textCardOutline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.brandBlue, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _buildFilterToggle('Toate', _typeFilter == 'Toate', () => setState(() => _typeFilter = 'Toate'), theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterToggle('Oraș', _typeFilter == AppConstants.addressTypeCity, () => setState(() => _typeFilter = AppConstants.addressTypeCity), theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildFilterToggle('Rute', _typeFilter == AppConstants.addressTypeRoute, () => setState(() => _typeFilter = AppConstants.addressTypeRoute), theme)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _openDateMenu(context, theme),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: theme.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.date_range_rounded, color: theme.brandBlue, size: 18),
                  const SizedBox(width: 10),
                  Text(_formatDateRange(_selectedDateRange), style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
                Icon(Icons.keyboard_arrow_down, color: theme.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: theme.brandBlue))
              : filteredComenzi.isEmpty
                  ? const SoferIstoricEmpty()
                  : SoferIstoricList(comenzi: filteredComenzi),
        ),
      ],
    );
  }

  // --- HELPERS UI ---
  Widget _buildFilterToggle(String text, bool isActive, VoidCallback onTap, ThemeProvider theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? theme.brandBlue : theme.filterCardFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? theme.textPrimary : theme.filterCardOutline, width: 1.0),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? theme.textPrimary : theme.filterText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color valueColor, ThemeProvider theme) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: theme.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.cardOutline, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    SoferShellState.of(context)?.switchTab(index);
  }

}

