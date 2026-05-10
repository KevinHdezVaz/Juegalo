import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Widget que reemplaza una sección cuando el feature flag está desactivado.
/// Mostrar dentro del Scaffold de cada pantalla, como si fuera el body.
class FeatureDisabledScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const FeatureDisabledScreen({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_clock_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.azulSuave,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.azulPrimario),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textoPrimario,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textoSecundario,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
