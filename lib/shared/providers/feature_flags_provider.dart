import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

// ── Modelo ────────────────────────────────────────────────────────────────────
class FeatureFlags {
  final bool maintenanceMode;
  final bool surveysEnabled;
  final bool gamesEnabled;
  final bool cashoutEnabled;
  final bool videosEnabled;
  final bool referralsEnabled;

  const FeatureFlags({
    this.maintenanceMode  = false,
    this.surveysEnabled   = true,
    this.gamesEnabled     = true,
    this.cashoutEnabled   = true,
    this.videosEnabled    = true,
    this.referralsEnabled = true,
  });

  /// Defaults seguros: todo habilitado, sin mantenimiento.
  factory FeatureFlags.defaults() => const FeatureFlags();

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    bool get(String key, {bool fallback = true}) =>
        json[key] as bool? ?? fallback;

    return FeatureFlags(
      maintenanceMode  : get('maintenance_mode',  fallback: false),
      surveysEnabled   : get('surveys_enabled'),
      gamesEnabled     : get('games_enabled'),
      cashoutEnabled   : get('cashout_enabled'),
      videosEnabled    : get('videos_enabled'),
      referralsEnabled : get('referrals_enabled'),
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    final response = await dio.get('${AppConstants.apiBaseUrl}/api/flags');

    if (response.statusCode == 200 && response.data is Map) {
      final flags = FeatureFlags.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      debugPrint(
        '🚩 [FeatureFlags] cargados — '
        'maintenance=${flags.maintenanceMode} '
        'games=${flags.gamesEnabled} '
        'surveys=${flags.surveysEnabled} '
        'cashout=${flags.cashoutEnabled}',
      );
      return flags;
    }
  } catch (e) {
    debugPrint('🟡 [FeatureFlags] Error al cargar flags (usando defaults): $e');
  }

  // En caso de error de red, la app funciona con defaults seguros.
  return FeatureFlags.defaults();
});
