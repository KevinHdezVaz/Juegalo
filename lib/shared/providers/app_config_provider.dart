import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';

/// Configuración remota de la app (no secreta).
/// Se carga una sola vez al inicio.
class AppConfig {
  /// adjoe SDK App ID. Vacío = adjoe no activado aún.
  final String adjoeAppId;

  const AppConfig({this.adjoeAppId = ''});

  bool get adjoeReady => adjoeAppId.isNotEmpty;

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    adjoeAppId: json['adjoe_app_id'] as String? ?? '',
  );
}

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final res = await dio.get('${AppConstants.apiBaseUrl}/api/config');
    if (res.statusCode == 200 && res.data is Map) {
      final config = AppConfig.fromJson(Map<String, dynamic>.from(res.data as Map));
      debugPrint('⚙️ [AppConfig] adjoeAppId=${config.adjoeAppId.isEmpty ? "no configurado" : "✓"}');
      return config;
    }
  } catch (e) {
    debugPrint('🟡 [AppConfig] Error cargando config: $e');
  }
  return const AppConfig();
});
