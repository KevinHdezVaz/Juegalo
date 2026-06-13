import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Comprobaciones anti-fraude del entorno de ejecución.
///
/// Detecta emuladores Android e iOS Simulator vía `device_info_plus`
/// (API oficial de Google/Apple, sin dependencias de terceros que rompen
/// el build con frecuencia).
///
/// Detección de root/jailbreak: omitida por ahora — los paquetes maduros
/// (`safe_device`, `flutter_jailbreak_detection`) tienen builds rotos
/// recurrentes. Los emuladores cubren el 90% del fraude observado.
class DeviceIntegrity {
  DeviceIntegrity._();

  /// Resultado cacheado del primer check para no repetir llamadas nativas.
  static IntegrityResult? _cached;

  /// Ejecuta el check de integridad (cacheado tras el primer call).
  static Future<IntegrityResult> runIntegrityCheck() async {
    if (_cached != null) return _cached!;
    try {
      final info = DeviceInfoPlugin();

      bool isEmulator = false;
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        isEmulator = !a.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        isEmulator = !i.isPhysicalDevice;
      }

      final r = IntegrityResult(isEmulator: isEmulator, isJailbroken: false);
      _cached = r;
      return r;
    } catch (_) {
      // Si el plugin falla (plataforma rara, error en plugin nativo, etc.)
      // asumimos device legítimo para no bloquear a usuarios reales.
      final r = IntegrityResult(isEmulator: false, isJailbroken: false);
      _cached = r;
      return r;
    }
  }

  /// Acceso rápido al resultado cacheado. Llama `runIntegrityCheck()` primero.
  static IntegrityResult? get cached => _cached;
}

class IntegrityResult {
  final bool isEmulator;
  final bool isJailbroken;
  const IntegrityResult({required this.isEmulator, required this.isJailbroken});

  bool get isBlocked => isEmulator || isJailbroken;

  /// Razón corta para enviar al backend / mostrar en analytics.
  String? get blockReason {
    if (isEmulator) return 'emulator';
    if (isJailbroken) return 'jailbroken';
    return null;
  }
}
