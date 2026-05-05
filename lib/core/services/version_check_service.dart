import 'dart:io';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/l10n_ext.dart';

// IDs de las tiendas — reemplaza el App Store ID cuando lo tengas
const _androidPackage = 'com.kevinhv.juegalo';
const _iosAppId       = 'XXXXXXXXX'; // reemplaza con tu Apple App ID numérico

class VersionCheckService {
  VersionCheckService._();
  static final instance = VersionCheckService._();

  final _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout:         const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Defaults: sin forzar actualización
    await _remoteConfig.setDefaults({
      'min_version':  '1.0.0',
      'force_update': false,
    });

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Si falla el fetch, usamos los defaults → no bloqueamos al usuario
    }
  }

  /// Llama esto en el splash. Si retorna true, se mostró el dialog de update.
  Future<bool> checkAndPromptUpdate(BuildContext context) async {
    try {
      final forceUpdate = _remoteConfig.getBool('force_update');
      if (!forceUpdate) return false;

      final minVersion = _remoteConfig.getString('min_version');
      final info       = await PackageInfo.fromPlatform();
      final current    = info.version;

      if (!_isOutdated(current, minVersion)) return false;

      if (context.mounted) {
        await _showUpdateDialog(context, current, minVersion);
      }
      return true;
    } catch (e) {
      // Nunca bloquear al usuario por un error en la verificación
      debugPrint('🟡 [VersionCheck] Error al verificar versión: $e');
      return false;
    }
  }

  /// Compara semver: retorna true si current < required
  bool _isOutdated(String current, String required) {
    final c = _parse(current);
    final r = _parse(required);
    for (var i = 0; i < 3; i++) {
      if (c[i] < r[i]) return true;
      if (c[i] > r[i]) return false;
    }
    return false;
  }

  List<int> _parse(String v) {
    final parts = v.trim().split('.');
    final major = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final minor = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final patch = int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0;
    return [major, minor, patch];
  }

  Future<void> _showUpdateDialog(
      BuildContext context, String current, String required) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => const PopScope(
        canPop: false,
        child: _UpdateDialog(),
      ),
    );
  }

  Future<void> _openStore() async {
    final url = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/app/id$_iosAppId')
        : Uri.parse('https://play.google.com/store/apps/details?id=$_androidPackage');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Dialog animado de actualización ─────────────────────────────────
class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog();

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _slideAnim = Tween<double>(begin: 40, end: 0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shimmerAnim = _shimmerCtrl;

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedBuilder(
        animation: _slideAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1729),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header con gradiente ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      children: [
                        // Logo con pulse
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/icons/app_icon.png',
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'JUEGALO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Builder(builder: (ctx) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ctx.l10n.versionNewAvailable,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),

                  // ── Contenido ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Column(
                      children: [
                        Builder(builder: (ctx) => Text(
                          ctx.l10n.versionUpdateTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        )),
                        const SizedBox(height: 12),
                        Builder(builder: (ctx) => Text(
                          ctx.l10n.versionUpdateBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        )),
                        const SizedBox(height: 24),

                        // ── Botón con shimmer ──────────────────────
                        AnimatedBuilder(
                          animation: _shimmerAnim,
                          builder: (_, __) {
                            return GestureDetector(
                              onTap: VersionCheckService.instance._openStore,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: const [
                                      Color(0xFF1D4ED8),
                                      Color(0xFF3B82F6),
                                      Color(0xFF2563EB),
                                    ],
                                    stops: [
                                      (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                                      _shimmerAnim.value.clamp(0.0, 1.0),
                                      (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Builder(builder: (ctx) => Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.system_update_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      ctx.l10n.versionUpdateButton,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                )),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Builder(builder: (ctx) => Text(
                          ctx.l10n.versionUpdateNote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
