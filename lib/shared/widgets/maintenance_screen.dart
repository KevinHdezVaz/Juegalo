import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feature_flags_provider.dart';

/// Pantalla de mantenimiento premium con:
/// - Engranajes animados girando
/// - Puntos de carga pulsantes
/// - Mensaje de "regresamos en unas horas"
/// - Contador de auto-reintento (cada 60 s)
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with TickerProviderStateMixin {
  // ── Animaciones ───────────────────────────────────────────────────
  late final AnimationController _gearBig;
  late final AnimationController _gearSmall;
  late final AnimationController _pulse;
  late final AnimationController _fadeIn;

  // ── Contador de auto-reintento ────────────────────────────────────
  static const _retryEvery = 60; // segundos
  int _secondsLeft = _retryEvery;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _gearBig = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _gearSmall = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: false);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

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
    _gearBig.dispose();
    _gearSmall.dispose();
    _pulse.dispose();
    _fadeIn.dispose();
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
            colors: [Color(0xFF0F1B3D), Color(0xFF1A2F6B), Color(0xFF0F1B3D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Engranajes animados ──────────────────────────────
                _GearsWidget(gearBig: _gearBig, gearSmall: _gearSmall),

                const SizedBox(height: 40),

                // ── Logo + título ────────────────────────────────────
                const Text(
                  'JUEGALO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white54,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'En mantenimiento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Descripción ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Estamos haciendo mejoras para darte\nuna mejor experiencia. 🚀',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha:0.65),
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Tarjeta de tiempo estimado ───────────────────────
                _TimeCard(pulse: _pulse),

                const SizedBox(height: 40),

                // ── Puntos de progreso animados ──────────────────────
                _BouncingDots(pulse: _pulse),

                const Spacer(flex: 3),

                // ── Contador + botón ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // Barra de progreso del countdown
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
                          color: Colors.white.withValues(alpha:0.45),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Botón reintentar ahora
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _retryNow,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reintentar ahora'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha:0.3),
                            ),
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

// ── Tarjeta de tiempo estimado ─────────────────────────────────────────────
class _TimeCard extends StatelessWidget {
  final AnimationController pulse;
  const _TimeCard({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = pulse.value * 0.15;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.06 + glow),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.12 + glow),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha:0.08 + glow * 0.5),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha:0.15),
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
        );
      },
    );
  }
}

// ── Engranajes animados ───────────────────────────────────────────────────
class _GearsWidget extends StatelessWidget {
  final AnimationController gearBig;
  final AnimationController gearSmall;

  const _GearsWidget({required this.gearBig, required this.gearSmall});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow detrás
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha:0.25),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Engranaje grande (izquierda, gira horario)
          Positioned(
            left: 0,
            top: 20,
            child: AnimatedBuilder(
              animation: gearBig,
              builder: (_, __) => Transform.rotate(
                angle: gearBig.value * 2 * math.pi,
                child: const _GearIcon(size: 72, color: Color(0xFF3B82F6)),
              ),
            ),
          ),

          // Engranaje pequeño (derecha, gira antihorario)
          Positioned(
            right: 0,
            top: 0,
            child: AnimatedBuilder(
              animation: gearSmall,
              builder: (_, __) => Transform.rotate(
                angle: -gearSmall.value * 2 * math.pi,
                child: const _GearIcon(size: 52, color: Color(0xFF60A5FA)),
              ),
            ),
          ),

          // Engranaje mini (abajo derecha, gira horario más rápido)
          Positioned(
            right: 8,
            bottom: 0,
            child: AnimatedBuilder(
              animation: gearSmall,
              builder: (_, __) => Transform.rotate(
                angle: gearSmall.value * 2 * math.pi * 1.5,
                child: const _GearIcon(size: 34, color: Color(0xFF93C5FD)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Icono de engranaje dibujado con CustomPainter ─────────────────────────
class _GearIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _GearIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GearPainter(color: color),
    );
  }
}

class _GearPainter extends CustomPainter {
  final Color color;
  const _GearPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width * 0.46;
    final innerR = size.width * 0.30;
    final holeR  = size.width * 0.16;
    const teeth  = 8;

    final path = Path();
    for (int i = 0; i < teeth; i++) {
      final baseAngle  = (i / teeth) * 2 * math.pi;
      final toothAngle = (math.pi / teeth) * 0.6;

      // Base del diente (innerR)
      path.moveTo(
        cx + innerR * math.cos(baseAngle - toothAngle),
        cy + innerR * math.sin(baseAngle - toothAngle),
      );
      // Punta del diente (outerR)
      path.lineTo(
        cx + outerR * math.cos(baseAngle - toothAngle * 0.3),
        cy + outerR * math.sin(baseAngle - toothAngle * 0.3),
      );
      path.lineTo(
        cx + outerR * math.cos(baseAngle + toothAngle * 0.3),
        cy + outerR * math.sin(baseAngle + toothAngle * 0.3),
      );
      // Base del siguiente valle
      path.lineTo(
        cx + innerR * math.cos(baseAngle + toothAngle),
        cy + innerR * math.sin(baseAngle + toothAngle),
      );
    }
    path.close();
    canvas.drawPath(path, paint);

    // Círculo interior del engranaje
    canvas.drawCircle(Offset(cx, cy), innerR, paint);

    // Agujero central
    canvas.drawCircle(Offset(cx, cy), holeR, Paint()..color = const Color(0xFF0F1B3D));
  }

  @override
  bool shouldRepaint(_GearPainter old) => old.color != color;
}

// ── Puntos de carga pulsantes ────────────────────────────────────────────
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
            // Cada punto desfasado 120°
            final offset = math.sin(
              (pulse.value * 2 * math.pi) - (i * math.pi * 0.66),
            );
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha:
                  0.3 + (offset.clamp(-1.0, 1.0) + 1) / 2 * 0.55,
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
