import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/version_check_service.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../tutorial/screens/tutorial_screen.dart';

// ── Partícula de moneda ───────────────────────────────────────────────────────
class _CoinData {
  final double x;
  final double phaseOffset;
  final double size;
  final double opacity;
  final double rotationDir;
  final double speed;
  final String emoji;

  const _CoinData({
    required this.x,
    required this.phaseOffset,
    required this.size,
    required this.opacity,
    required this.rotationDir,
    required this.speed,
    required this.emoji,
  });
}

// ── SplashScreen ──────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  // Animación de entrada del logo
  late final AnimationController _entryCtrl;
  late final Animation<double>   _fade;
  late final Animation<double>   _scale;

  // Monedas cayendo
  late final AnimationController _coinsCtrl;
  late final List<_CoinData>     _coins;

  // Flotación del logo
  late final AnimationController _floatCtrl;
  late final Animation<double>   _logoFloat;

  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();

    // ── Partículas ──────────────────────────────────────────────────
    const emojis = ['🪙', '🪙', '🪙', '💰', '⭐', '🪙', '💵', '🪙'];
    _coins = List.generate(24, (i) => _CoinData(
      x:           rng.nextDouble(),
      phaseOffset: rng.nextDouble(),
      size:        14 + rng.nextDouble() * 18,
      opacity:     0.30 + rng.nextDouble() * 0.50,
      rotationDir: rng.nextBool() ? 1.0 : -1.0,
      speed:       0.10 + rng.nextDouble() * 0.20,
      emoji:       emojis[rng.nextInt(emojis.length)],
    ));

    // ── Entry animation ─────────────────────────────────────────────
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.75, end: 1.0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _entryCtrl.forward();

    // ── Coins loop ──────────────────────────────────────────────────
    _coinsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    // ── Logo float ──────────────────────────────────────────────────
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _logoFloat = Tween<double>(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _navigate();
  }

  Future<void> _navigate() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;

      final needsUpdate =
          await VersionCheckService.instance.checkAndPromptUpdate(context);
      if (needsUpdate) return;
      if (!mounted) return;

      await NotificationService.instance.checkInitialMessage();
      if (!mounted) return;

      final session = ref.read(currentSessionProvider);
      if (session != null) {
        _notifSub = NotificationService.instance.onNavigate.listen((route) {
          if (mounted) context.go(route);
        });
      }

      final tutorialDone = await isTutorialCompleted();
      if (!mounted) return;

      if (!tutorialDone) {
        context.go(AppRoutes.tutorial);
        return;
      }

      context.go(session != null ? AppRoutes.home : AppRoutes.onboarding);
    } catch (e, st) {
      debugPrint('❌ [Splash] Error en _navigate: $e\n$st');
      if (!mounted) return;
      try {
        final session = Supabase.instance.client.auth.currentSession;
        context.go(session != null ? AppRoutes.home : AppRoutes.onboarding);
      } catch (_) {
        context.go(AppRoutes.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _entryCtrl.dispose();
    _coinsCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F8A),
      body: Stack(
        children: [

          // ── Fondo degradado ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1F8A),
                  Color(0xFF1A3FCC),
                  Color(0xFF2563EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Círculos decorativos de fondo ───────────────────────────
          Positioned(
            top: -100, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.35, right: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // ── Monedas cayendo ─────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final w = constraints.maxWidth;
              return AnimatedBuilder(
                animation: _coinsCtrl,
                builder: (_, __) => Stack(
                  children: _coins.map((coin) {
                    final phase =
                        (_coinsCtrl.value * coin.speed + coin.phaseOffset) % 1.0;
                    final x = coin.x * w - coin.size / 2;
                    final y = -coin.size * 2 + (h + coin.size * 3) * phase;
                    double alpha = coin.opacity;
                    if (phase < 0.06) alpha *= phase / 0.06;
                    if (phase > 0.88) alpha *= (1.0 - phase) / 0.12;
                    final angle =
                        phase * math.pi * 2.0 * coin.rotationDir;
                    return Positioned(
                      left: x,
                      top: y,
                      child: Opacity(
                        opacity: alpha.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: angle,
                          child: coin.emoji == '🪙'
                              ? Icon(Icons.monetization_on,
                                  color: Colors.amber, size: coin.size)
                              : Text(coin.emoji,
                                  style: TextStyle(
                                      fontSize: coin.size, height: 1)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // ── Contenido central ───────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Logo flotante
                    AnimatedBuilder(
                      animation: _logoFloat,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _logoFloat.value),
                        child: child,
                      ),
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: -4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            width: 120, height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Nombre de la app
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        AppConstants.appTagline.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Indicador de carga
                    SizedBox(
                      width: 26, height: 26,
                      child: CircularProgressIndicator(
                        color: Colors.white.withValues(alpha: 0.8),
                        strokeWidth: 2.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      context.l10n.splashLoading,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
