import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio que pide un Play Integrity token al device y lo envía al
/// backend para verificación con Google Play Integrity API.
///
/// El verdict del backend dice si:
///   - La app NO está modificada (APK firma legítima de Play Store)
///   - El device es legítimo (no emulador, no rooted-malicious)
///   - La app fue instalada vía Play Store (no APK pirata)
///
/// Resultado se cachea — no llamamos en cada acción, solo en momentos críticos:
///   - app_start (al arrancar)
///   - before_withdrawal (antes de pedir retiro grande)
///   - before_daily_bonus (antes de cobrar bono)
///
/// En iOS: skip (DeviceCheck/AppAttest requiere setup separado).
class PlayIntegrityService {
  PlayIntegrityService._();

  /// Canal nativo que conecta con `MainActivity.kt` para pedir el integrity
  /// token a Google Play Services.
  static const _nativeChannel = MethodChannel('juegalo.app/play_integrity');

  static IntegrityVerdict? _cachedAppStart;
  static bool _running = false;

  /// True si el último check pasó. Default true mientras no haya check.
  static bool get isLegit => _cachedAppStart?.ok ?? true;

  /// Razón del último fallo (para mostrar al usuario o loggear).
  static String? get failureReason => _cachedAppStart?.reason;

  /// Llamar al arrancar la app (después del login para que tengamos JWT).
  /// Solo bloquea en RELEASE — en debug pasa siempre para no estorbar dev.
  static Future<IntegrityVerdict> checkAtAppStart() async {
    if (_cachedAppStart != null) return _cachedAppStart!;
    if (_running) return const IntegrityVerdict(ok: true, reason: 'pending');
    _running = true;
    try {
      final v = await _runCheck(action: 'app_start');
      _cachedAppStart = v;
      return v;
    } finally {
      _running = false;
    }
  }

  /// Llamar antes de operaciones críticas (cobrar PayPal, etc).
  /// No cachea — siempre fresh.
  static Future<IntegrityVerdict> checkBeforeAction(String action) async {
    return _runCheck(action: action);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  /// TEMP: poner en `true` para forzar el check de integrity incluso en debug.
  /// Cuando termines de probar, volver a `false`.
  static const bool _forceInDebug = false;

  static Future<IntegrityVerdict> _runCheck({required String action}) async {
    debugPrint('🛡 ───────────────────────────────────────────────');
    debugPrint('🛡 [PlayIntegrity] _runCheck START — action=$action');
    debugPrint('🛡 [PlayIntegrity] kReleaseMode=$kReleaseMode forceInDebug=$_forceInDebug');

    // En DEBUG no llamamos a Google → siempre legit
    if (!kReleaseMode && !_forceInDebug) {
      debugPrint('🛡 [PlayIntegrity] → SKIP (debug, no forceInDebug)');
      return const IntegrityVerdict(ok: true, reason: 'debug_skipped');
    }

    // En iOS: skip por ahora
    if (!Platform.isAndroid) {
      debugPrint('🛡 [PlayIntegrity] → SKIP (iOS, no soportado)');
      return const IntegrityVerdict(ok: true, reason: 'ios_skipped');
    }

    // Sin sesión activa: no podemos invocar la Edge Function (requiere JWT)
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      debugPrint('🛡 [PlayIntegrity] → SKIP (no hay sesión activa)');
      return const IntegrityVerdict(ok: true, reason: 'no_session');
    }
    debugPrint('🛡 [PlayIntegrity] uid=$uid → procediendo');

    try {
      // 1) Generar nonce único — anti-replay
      final nonce = _generateNonce();
      debugPrint('🛡 [PlayIntegrity] STEP 1: nonce generado (${nonce.length} chars)');

      // 2) Pedir token REAL a Google Play Services vía MethodChannel nativo.
      debugPrint('🛡 [PlayIntegrity] STEP 2: pidiendo token a IntegrityManager nativo...');
      String tokenResp;
      try {
        final result = await _nativeChannel.invokeMethod<String>(
          'getToken',
          {'nonce': nonce},
        );
        tokenResp = result ?? '';
        debugPrint('🛡 [PlayIntegrity] STEP 2 ✅ token recibido (${tokenResp.length} chars)');
        if (tokenResp.length > 30) {
          debugPrint('🛡 [PlayIntegrity]   preview: ${tokenResp.substring(0, 30)}...');
        }
      } on PlatformException catch (e) {
        debugPrint('🛡 [PlayIntegrity] STEP 2 🔴 PlatformException');
        debugPrint('🛡 [PlayIntegrity]   code: ${e.code}');
        debugPrint('🛡 [PlayIntegrity]   message: ${e.message}');
        debugPrint('🛡 [PlayIntegrity]   details: ${e.details}');

        // Timeout = emulador / device problemático que cuelga el call.
        // Esos SÍ deben bloquearse en cobros — Google nunca devuelve token
        // para emuladores aunque el binding inicial funcione.
        if (e.code == 'INTEGRITY_TIMEOUT') {
          return const IntegrityVerdict(
            ok: false,
            reason: 'device_no_integrity', // mismo string que activa shouldStrictlyBlock
          );
        }

        return IntegrityVerdict(
          ok: true, // otros errores del SDK no bloquean (red mala, etc.)
          reason: 'native_${e.code}: ${e.message}',
        );
      }

      if (tokenResp.isEmpty) {
        debugPrint('🛡 [PlayIntegrity] STEP 2 🟡 token vacío — skip');
        return const IntegrityVerdict(ok: true, reason: 'empty_token');
      }

      // 3) Mandar al backend para verificar con Google
      debugPrint('🛡 [PlayIntegrity] STEP 3: enviando a Edge Function verify-play-integrity...');
      final res = await Supabase.instance.client.functions.invoke(
        'verify-play-integrity',
        body: {
          'token': tokenResp,
          'platform': 'android',
          'action': action,
          'nonce': nonce,
          'user_id': uid,
        },
      );

      debugPrint('🛡 [PlayIntegrity] STEP 3 ← respuesta Edge Function');
      debugPrint('🛡 [PlayIntegrity]   status: ${res.status}');
      debugPrint('🛡 [PlayIntegrity]   data:   ${res.data}');

      final data = res.data as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('🛡 [PlayIntegrity] 🟡 sin respuesta — skip');
        return const IntegrityVerdict(ok: true, reason: 'no_response');
      }

      final ok = data['ok'] == true && data['verdict'] == 'pass';
      final reason = data['reason']?.toString() ?? data['warning']?.toString();
      final detail = data['detail'];
      debugPrint('🛡 [PlayIntegrity] RESULTADO FINAL:');
      debugPrint('🛡 [PlayIntegrity]   ok:     $ok');
      debugPrint('🛡 [PlayIntegrity]   reason: $reason');
      debugPrint('🛡 [PlayIntegrity]   detail: $detail');
      debugPrint('🛡 ───────────────────────────────────────────────');
      return IntegrityVerdict(ok: ok, reason: reason);
    } catch (e, stack) {
      debugPrint('🛡 [PlayIntegrity] 🔴 EXCEPCIÓN: $e');
      debugPrint('🛡 [PlayIntegrity] stack: $stack');
      return IntegrityVerdict(ok: true, reason: 'error: $e');
    }
  }

  static String _generateNonce() {
    final r = Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

class IntegrityVerdict {
  final bool ok;
  final String? reason;
  const IntegrityVerdict({required this.ok, this.reason});

  /// True si el verdict indica una violación de integridad GRAVE que sí
  /// debemos bloquear.
  ///
  /// Razones que bloquean:
  ///   • `device_no_integrity` — emulador detectado por device verdict
  ///   • `app_UNRECOGNIZED_VERSION` — APK modificado / no es el publicado
  ///   • `app_UNEVALUATED` — Google se rehúsa a evaluar (firma de emulador
  ///     que cuelga el call y devuelve UNEVALUATED en todo)
  ///
  /// Razones que NO bloquean (no son culpa del usuario):
  ///   • errores de red, timeouts del SDK distintos a INTEGRITY_TIMEOUT,
  ///     `no_session`, `debug_skipped`, `ios_skipped`, etc.
  bool get shouldStrictlyBlock {
    if (ok) return false;
    final r = reason ?? '';
    return r.contains('device_no_integrity') ||
        r.contains('app_UNRECOGNIZED_VERSION') ||
        r.contains('app_UNEVALUATED');
  }
}
