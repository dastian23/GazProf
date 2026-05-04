import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // --- BACKGROUND COLORS ---
  Color get scaffoldBg => _isDark ? Colors.black : const Color(0xFFF7F7F7);

  // Fundalul pentru zona de profil de sus: Negru pe Dark, Alb pe Light
  Color get headerBg => _isDark ? Colors.black : Colors.white;

  Color get backCircle => _isDark ? const Color(0xFF312F2F) : const Color(0xFFD9D9D9);

  // --- CARD COLORS ---
  // Pe Light, cardurile (placeholderele) devin albe conform noii cerințe
  Color get cardFill => _isDark ? const Color(0xFF312F2F) : Colors.white;
  Color get cardOutline => _isDark ? Colors.white : const Color(0xFFD1D1D1);

  // --- SECTION LABELS (CONT, PREFERINȚE) ---
  // Alb pe Dark, D1D1D1 pe Light
  Color get sectionLabel => _isDark ? Colors.white : const Color(0xFFD1D1D1);

  // --- TEXTBOX COLORS ---
  Color get textFieldFill => _isDark ? const Color(0xFF312F2F) : Colors.white;
  Color get textFieldOutline => _isDark ? Colors.white : const Color(0xFFD1D1D1);
  Color get textFieldIcon => _isDark ? Colors.white : Colors.black;

  // --- TEXT COLOR ---
  Color get textPrimary => _isDark ? Colors.white : Colors.black;
  Color get textSecondary => _isDark ? Colors.white60 : const Color(0xFF888888);
  Color get textGriFix => const Color(0xFF888888);
  Color get linkBlue => const Color(0xFF0779B7);

  // --- BTN COLOR ---
  Color get brandBlue => const Color(0xFF0779B7);
  Color get buttonText => _isDark ? Colors.white : Colors.black;
  Color get buttonOutline => _isDark ? Colors.white : Colors.black;

  // Umbra butonului: Albă pe Dark, Neagră pe Light
  List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: _isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    )
  ];

  // --- NAV BAR ---
  Color get navBarBg => _isDark ? const Color(0xFF888888) : const Color(0xFFEEEEEE);
  Color get navIconColor => _isDark ? Colors.white : const Color(0xFF888888);
  Color get activeNavCircle => const Color(0xFF0779B7);
  Color get navIconUnselected => _isDark ? const Color(0xFF312F2F) : const Color (0xFF888888);

  // --- PROFILE ICONS COLORS ---
  Color get iconPerson => const Color(0xFFFF6B00);
  Color get bgPerson => const Color(0xFFFF6B00).withValues(alpha: 0.2);

  Color get iconLock => const Color(0xFF0779B7);
  Color get bgLock => const Color(0xFF0779B7).withValues(alpha: 0.2);

  Color get iconMaps => const Color(0xFF888888);
  Color get bgMaps => const Color(0xFFD1D1D1).withValues(alpha: 0.3);

  Color get iconLogout => const Color(0xFFFF0000);
  Color get bgLogout => const Color(0xFFFF0000).withValues(alpha: 0.3);

  // --- SHADOW LOGIC ---
  List<BoxShadow> get generalShadow => [
    BoxShadow(
      color: _isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.2),
      blurRadius: 12,
      spreadRadius: 1,
      offset: _isDark ? Offset.zero : const Offset(0, 4),
    ),
  ];
}