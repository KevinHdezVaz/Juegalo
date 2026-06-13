import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/device_integrity.dart';
import '../../core/constants/app_colors.dart';

/// Pantalla bloqueante que se muestra cuando se detecta emulador o jailbreak.
/// Sin botón de "continuar" — el usuario debe cerrar la app.
class IntegrityBlockScreen extends StatelessWidget {
  final IntegrityResult result;
  const IntegrityBlockScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isEmu = result.isEmulator;
    final title = isEmu ? 'Emulador detectado' : 'Dispositivo no soportado';
    final desc = isEmu
        ? 'Por políticas anti-fraude, JUEGALO no funciona en emuladores. '
            'Instala la app en un dispositivo físico para continuar.'
        : 'Detectamos que este dispositivo tiene root/jailbreak. '
            'Por seguridad y políticas anti-fraude, la app no puede usarse '
            'en dispositivos modificados.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.fondoPrincipal,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFFDC2626), width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.gpp_bad_rounded,
                      color: Color(0xFFFCA5A5), size: 64),
                ),
                const SizedBox(height: 32),
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textoPrimario.withValues(alpha: 0.85),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Código: ${result.blockReason ?? "blocked"}',
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text(
                    'CERRAR APLICACIÓN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  onPressed: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
