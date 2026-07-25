import 'package:flutter/material.dart';

import '../../data/models/proposal.dart';

class AppColors {
  static const slate900 = Color(0xFF0F172A);
  static const slate700 = Color(0xFF334155);
  static const slate500 = Color(0xFF64748B);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const cream = Color(0xFFF7F8FA);
  static const teal = Color(0xFF0F766E);
  static const tealSoft = Color(0xFFCCFBF1);
  static const amber = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFEF3C7);
  static const blue = Color(0xFF1D4ED8);
  static const blueSoft = Color(0xFFDBEAFE);
  static const rose = Color(0xFFBE123C);
  static const roseSoft = Color(0xFFFFE4E6);
  static const ink = Color(0xFF111827);
}

class AppTheme {
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
      primary: AppColors.teal,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        surface: Colors.white,
        onSurface: AppColors.ink,
        surfaceContainerLowest: AppColors.cream,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Segoe UI',
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Segoe UI',
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Segoe UI',
          color: AppColors.slate700,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Segoe UI',
          color: AppColors.slate700,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Segoe UI',
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slate100,
        selectedColor: AppColors.tealSoft,
        labelStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.tealSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.teal : AppColors.slate500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.teal : AppColors.slate500,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.slate200),
    );
  }

  static Color statusColor(ProposalStatus status) {
    return switch (status) {
      ProposalStatus.hired => AppColors.teal,
      ProposalStatus.responded => AppColors.blue,
      ProposalStatus.viewed => AppColors.amber,
      ProposalStatus.rejected => AppColors.rose,
      ProposalStatus.submitted => AppColors.slate500,
    };
  }

  static Color statusSoftColor(ProposalStatus status) {
    return switch (status) {
      ProposalStatus.hired => AppColors.tealSoft,
      ProposalStatus.responded => AppColors.blueSoft,
      ProposalStatus.viewed => AppColors.amberSoft,
      ProposalStatus.rejected => AppColors.roseSoft,
      ProposalStatus.submitted => AppColors.slate100,
    };
  }
}
