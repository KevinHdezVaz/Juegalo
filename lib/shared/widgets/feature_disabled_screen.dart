import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/utils/l10n_ext.dart';

/// Colores temáticos por sección.
enum FeatureTheme {
  games,
  surveys,
  videos,
  cashout,
  referrals,
  generic,
}

extension _FeatureThemeX on FeatureTheme {
  List<Color> get gradientColors => switch (this) {
        FeatureTheme.games => [
            const Color(0xFF1E0547),
            const Color(0xFF3B1A8C)
          ],
        FeatureTheme.surveys => [
            const Color(0xFF012E1E),
            const Color(0xFF065F46)
          ],
        FeatureTheme.videos => [
            const Color(0xFF2D1200),
            const Color(0xFF92400E)
          ],
        FeatureTheme.cashout => [
            const Color(0xFF0F1B3D),
            const Color(0xFF1E3A7B)
          ],
        FeatureTheme.referrals => [
            const Color(0xFF2D0037),
            const Color(0xFF6B21A8)
          ],
        FeatureTheme.generic => [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B)
          ],
      };

  Color get accentColor => switch (this) {
        FeatureTheme.games => const Color(0xFFA78BFA),
        FeatureTheme.surveys => const Color(0xFF34D399),
        FeatureTheme.videos => const Color(0xFFFBBF24),
        FeatureTheme.cashout => const Color(0xFF60A5FA),
        FeatureTheme.referrals => const Color(0xFFD946EF),
        FeatureTheme.generic => const Color(0xFF94A3B8),
      };

  Color get iconBg => switch (this) {
        FeatureTheme.games => const Color(0xFF4C1D95),
        FeatureTheme.surveys => const Color(0xFF065F46),
        FeatureTheme.videos => const Color(0xFF78350F),
        FeatureTheme.cashout => const Color(0xFF1E3A8A),
        FeatureTheme.referrals => const Color(0xFF581C87),
        FeatureTheme.generic => const Color(0xFF334155),
      };
}

/// Widget premium para secciones desactivadas por feature flag.
/// Se muestra como `body` dentro del Scaffold de cada pantalla.
class FeatureDisabledScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final FeatureTheme theme;

  const FeatureDisabledScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.theme = FeatureTheme.generic,
  });

  @override
  State<FeatureDisabledScreen> createState() => _FeatureDisabledScreenState();
}

class _FeatureDisabledScreenState extends State<FeatureDisabledScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final accent = theme.accentColor;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [...theme.gradientColors, theme.gradientColors.first],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Icono con glow ──────────────────────────────────
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow exterior
                    Container(
                      width: 130 + _pulse.value * 14,
                      height: 130 + _pulse.value * 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(
                              alpha: 0.28 + _pulse.value * 0.15,
                            ),
                            blurRadius: 50 + _pulse.value * 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    // Anillo exterior
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: accent.withValues(
                            alpha: 0.25 + _pulse.value * 0.15,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Círculo de icono
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.iconBg,
                      ),
                      child: Icon(widget.icon, size: 40, color: accent),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Chip "Temporalmente desactivado" ───────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      context.l10n.maintenanceTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accent,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Título ─────────────────────────────────────────
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 14),

              // ── Subtítulo ──────────────────────────────────────
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.58),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 36),

              // ── Tarjeta de estado ──────────────────────────────
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.06 + _pulse.value * 0.03,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: 0.1 + _pulse.value * 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.15),
                        ),
                        child: Icon(
                          Icons.build_circle_rounded,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.maintenanceComingSoon,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.maintenanceWorking,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Puntos de actividad ────────────────────────────
              _ActivityDots(pulse: _pulse, accent: accent),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tres puntos pulsantes con color de acento ────────────────────────────
class _ActivityDots extends StatelessWidget {
  final AnimationController pulse;
  final Color accent;
  const _ActivityDots({required this.pulse, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: pulse,
          builder: (_, __) {
            final wave = math.sin(
              (pulse.value * 2 * math.pi) - (i * math.pi * 0.66),
            );
            final t = (wave.clamp(-1.0, 1.0) + 1) / 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.25 + t * 0.65),
              ),
              transform: Matrix4.translationValues(0, -wave * 4, 0),
            );
          },
        );
      }),
    );
  }
}
