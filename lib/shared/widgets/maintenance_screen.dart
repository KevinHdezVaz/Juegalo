import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feature_flags_provider.dart';

/// Pantalla de mantenimiento premium con:
/// - Logo de la app con glow pulsante
/// - Puntos de carga animados
/// - Mensaje "regresamos en unas horas"
/// - Auto-reintento con contador de 60 s
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _fadeIn;
  late final AnimationController _float;

  static const _retryEvery = 60;
  int _secondsLeft = _retryEvery;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsLeft = _retryEvery);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft <= 1) {
          _secondsLeft = _retryEvery;
          ref.invalidate(featureFlagsProvider);
        } else {
          _secondsLeft--;
        }
      });
    });
  }

  void _retryNow() {
    ref.invalidate(featureFlagsProvider);
    _startCountdown();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _fadeIn.dispose();
    _float.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F1B3D), Color(0xFF1E3A7B), Color(0xFF0F1B3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Logo flotante con glow ─────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _float]),
                  builder: (_, __) {
                    final glowSize = 110 + _pulse.value * 18;
                    final floatY   = math.sin(_float.value * math.pi) * 8;
                    return Transform.translate(
                      offset: Offset(0, floatY),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow exterior
                          Container(
                            width: glowSize,
                            height: glowSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35 + _pulse.value * 0.2),
                                  blurRadius: 40 + _pulse.value * 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          // Círculo de fondo
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15 + _pulse.value * 0.08),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // Logo de la app
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // ── Título ────────────────────────────────────────
                const Text(
                  'JUEGALO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white54,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'En mantenimiento',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Text(
                    'Estamos haciendo mejoras para darte\nuna mejor experiencia. 🚀',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.62),
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Tarjeta de tiempo estimado ────────────────────
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07 + _pulse.value * 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12 + _pulse.value * 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12 + _pulse.value * 0.08),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFF60A5FA),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Regresamos en unas horas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gracias por tu paciencia 🙏',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Puntos rebotando ──────────────────────────────
                _BouncingDots(pulse: _pulse),

                const Spacer(flex: 3),

                // ── Countdown + botón ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1 - (_secondsLeft / _retryEvery),
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                          minHeight: 3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Verificando automáticamente en $_secondsLeft s...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.42),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _retryNow,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reintentar ahora'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tres puntos rebotando ─────────────────────────────────────────────────
class _BouncingDots extends StatelessWidget {
  final AnimationController pulse;
  const _BouncingDots({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: pulse,
          builder: (_, __) {
            final offset = math.sin(
              (pulse.value * 2 * math.pi) - (i * math.pi * 0.66),
            );
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(
                  alpha: 0.3 + (offset.clamp(-1.0, 1.0) + 1) / 2 * 0.55,
                ),
              ),
              transform: Matrix4.translationValues(0, -offset * 5, 0),
            );
          },
        );
      }),
    );
  }
}
