import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Widget reutilizable para estados de error con botón de reintentar.
/// Úsalo en los `.when(error: ...)` de cualquier pantalla.
///
/// ```dart
/// error: (e, _) => AppErrorWidget(onRetry: () => ref.invalidate(myProvider)),
/// ```
class AppErrorWidget extends StatelessWidget {
  /// Callback al pulsar "Reintentar". Normalmente invalida el provider.
  final VoidCallback? onRetry;

  /// Mensaje personalizado. Si es null usa el texto por defecto.
  final String? message;

  const AppErrorWidget({super.key, this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.fondoCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fondoCardBorde),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textoDeshabilitado,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),

            // Título
            const Text(
              'Sin conexión',
              style: TextStyle(
                color: AppColors.textoPrimario,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),

            // Subtítulo
            Text(
              message ?? 'No pudimos cargar la información.\nVerifica tu conexión e intenta de nuevo.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrimario,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
