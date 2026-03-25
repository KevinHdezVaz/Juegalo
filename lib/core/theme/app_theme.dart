import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.fondoPrincipal,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.verdePrimario,
      secondary: AppColors.dorado,
      tertiary:  AppColors.morado,
      surface:   AppColors.fondoCard,
      error:     AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondoPrincipal,
      foregroundColor: AppColors.textoPrimario,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textoPrimario,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.fondoCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.fondoCardBorde),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.fondoElevado,
      selectedItemColor: AppColors.verdePrimario,
      unselectedItemColor: AppColors.textoDeshabilitado,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.verdePrimario,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w800, fontSize: 32),
      headlineMedium: TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w700, fontSize: 24),
      titleLarge:  TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium: TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge:   TextStyle(color: AppColors.textoPrimario, fontSize: 15),
      bodyMedium:  TextStyle(color: AppColors.textoSecundario, fontSize: 13),
      labelSmall:  TextStyle(color: AppColors.textoDeshabilitado, fontSize: 11),
    ),
  );
}
