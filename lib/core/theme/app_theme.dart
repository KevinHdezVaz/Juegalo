import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.fondoPrincipal,

    colorScheme: const ColorScheme.light(
      primary:   AppColors.azulPrimario,
      secondary: AppColors.dorado,
      tertiary:  AppColors.verdePrimario,
      surface:   AppColors.fondoCard,
      error:     AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.textoPrimario,
    ),

    // ── AppBar ────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor:  AppColors.fondoCard,
      foregroundColor:  AppColors.textoPrimario,
      elevation:        0,
      scrolledUnderElevation: 0,
      centerTitle:      false,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness:          Brightness.light,
        statusBarIconBrightness:      Brightness.dark,
        systemNavigationBarColor:     AppColors.fondoCard,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color:       AppColors.textoPrimario,
        fontSize:    18,
        fontWeight:  FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),

    // ── Cards ─────────────────────────────────────────────────
    cardTheme: CardTheme(
      color:     AppColors.fondoCard,
      elevation: 0,
      shadowColor: AppColors.sombra,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.fondoCardBorde),
      ),
    ),

    // ── BottomNav ─────────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     AppColors.fondoCard,
      selectedItemColor:   AppColors.azulPrimario,
      unselectedItemColor: AppColors.textoDeshabilitado,
      type:                BottomNavigationBarType.fixed,
      elevation:           0,
      selectedLabelStyle:  TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle:TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
    ),

    // ── Botones ───────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.azulPrimario,
        foregroundColor: Colors.white,
        elevation:       0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.azulPrimario,
        side:            const BorderSide(color: AppColors.fondoCardBorde),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.azulPrimario,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    // ── Inputs ────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled:           true,
      fillColor:        AppColors.fondoCard,
      hintStyle:        const TextStyle(color: AppColors.textoDeshabilitado),
      contentPadding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.fondoCardBorde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.fondoCardBorde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.azulPrimario, width: 1.5),
      ),
    ),

    // ── Divider ───────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color:     AppColors.fondoCardBorde,
      thickness: 1,
      space:     1,
    ),

    // ── Textos ────────────────────────────────────────────────
    textTheme: const TextTheme(
      headlineLarge:  TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w800, fontSize: 32),
      headlineMedium: TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w700, fontSize: 24),
      titleLarge:     TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium:    TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge:      TextStyle(color: AppColors.textoPrimario, fontSize: 15),
      bodyMedium:     TextStyle(color: AppColors.textoSecundario, fontSize: 13),
      labelSmall:     TextStyle(color: AppColors.textoDeshabilitado, fontSize: 11),
    ),
  );
}
