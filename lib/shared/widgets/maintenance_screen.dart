import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/feature_flags_provider.dart';

/// Pantalla de mantenimiento — se muestra cuando maintenance_mode = true.
/// El usuario puede pulsar "Reintentar" para volver a cargar los flags.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.azulSuave,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.build_rounded,
                  size: 56,
                  color: AppColors.azulPrimario,
                ),
              ),
              const SizedBox(height: 32),

              // Título
              const Text(
                'En mantenimiento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textoPrimario,
                ),
              ),
              const SizedBox(height: 16),

              // Descripción
              const Text(
                'Estamos mejorando la app para ti.\nVuelve a intentarlo en unos minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textoSecundario,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Botón reintentar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref.invalidate(featureFlagsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulPrimario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
