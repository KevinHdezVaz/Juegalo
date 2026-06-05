import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog premium que promociona otra app del mismo desarrollador.
/// Animación de entrada + glassmorphism + rating + CTA con shimmer.
class CrossPromoDialog extends StatefulWidget {
  const CrossPromoDialog({super.key});

  // ── DATOS DE LA APP A PROMOCIONAR ─────────────────────────────────
  static const String _promoAppName    = 'Winner - Gana dinero jugando';
  static const String _promoAppTagline = 'Juega, gana y retira a PayPal';
  static const String _promoAppUrlAndroid =
      'https://play.google.com/store/apps/details?id=com.kevinGame.winner&hl=es_MX';
  static const String _promoAppUrlIos =
      'https://apps.apple.com/us/app/winner-gana-dinero-jugando/id6769851325';
  static String get _promoAppUrl =>
      Platform.isIOS ? _promoAppUrlIos : _promoAppUrlAndroid;
  static const String _promoAppIconUrl =
      'https://play-lh.googleusercontent.com/Ye_p03ap5KbWGKUeTXf82_1ihiuSe9SElq_a7zjOHyO1NpTgd_B25M2rPJQvjncaEAF2BFatbfjxARJDDlIS=w240-h480';
  // ──────────────────────────────────────────────────────────────────

  static const String _prefsKey = 'cross_promo_last_shown';
  static const Duration _cooldown = Duration(days: 3);

  // 🧪 TESTING: si es true, ignora cooldown y siempre muestra el dialog.
  // ⚠️ Cambia a false antes de generar el AAB de release.
  static const bool _debugAlwaysShow = false;

  /// Llama esto desde HomeScreen.initState — verifica si toca mostrar el dialog.
  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownMs = prefs.getInt(_prefsKey) ?? 0;
    final now = DateTime.now();
    final lastShown = DateTime.fromMillisecondsSinceEpoch(lastShownMs);

    if (!_debugAlwaysShow) {
      if (lastShownMs == 0) {
        await prefs.setInt(_prefsKey,
            now.subtract(_cooldown - const Duration(days: 2)).millisecondsSinceEpoch);
        return;
      }
      if (now.difference(lastShown) < _cooldown) return;
    }

    if (!context.mounted) return;
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    await prefs.setInt(_prefsKey, now.millisecondsSinceEpoch);
    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => const CrossPromoDialog(),
      transitionBuilder: (_, anim, __, child) {
        final scale = Tween<double>(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack))
            .animate(anim);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }

  @override
  State<CrossPromoDialog> createState() => _CrossPromoDialogState();
}

class _CrossPromoDialogState extends State<CrossPromoDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _openStore(BuildContext context) async {
    final uri = Uri.parse(CrossPromoDialog._promoAppUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1F3A),
                    Color(0xFF0F1729),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // ─── Halo de fondo radial ─────────────────────────
                  Positioned(
                    top: -60,
                    left: -40,
                    right: -40,
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.30),
                            const Color(0xFF10B981).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ─── Botón cerrar ────────────────────────────────
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              color: Colors.white.withValues(alpha: 0.7), size: 18),
                        ),
                      ),
                    ),
                  ),
                  // ─── Contenido ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBadge(),
                        const SizedBox(height: 22),
                        _buildHeroIcon(),
                        const SizedBox(height: 18),
                        _buildTitle(),
                        const SizedBox(height: 8),
                        _buildRating(),
                        const SizedBox(height: 6),
                        _buildTagline(),
                        const SizedBox(height: 20),
                        _buildFeatures(),
                        const SizedBox(height: 22),
                        _buildCTA(),
                        const SizedBox(height: 10),
                        _buildDismiss(),
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

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.18),
            const Color(0xFF6366F1).withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('✨', style: TextStyle(fontSize: 12)),
          SizedBox(width: 6),
          Text(
            'DEL MISMO CREADOR DE JUEGALO',
            style: TextStyle(
              color: Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.55),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              CrossPromoDialog._promoAppIconUrl,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.attach_money_rounded,
                    color: Colors.white, size: 48),
              ),
            ),
          ),
          // Glossy overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      CrossPromoDialog._promoAppName,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 21,
        fontWeight: FontWeight.w900,
        height: 1.15,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
              color: const Color(0xFFFCD34D),
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '4.7',
          style: TextStyle(
            color: Color(0xFFFCD34D),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '+10K descargas',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      CrossPromoDialog._promoAppTagline,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: 13.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFeatures() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Feature(emoji: '💸', label: 'Paga\nreal'),
          _DividerVertical(),
          _Feature(emoji: '🎁', label: 'Bono\ninicial'),
            _DividerVertical(),
          _Feature(emoji: '⚡', label: 'Pagos\nRapidos'),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openStore(context),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedBuilder(
            animation: _shimmer,
            builder: (_, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                      Color(0xFF10B981),
                    ],
                    stops: [
                      0.0,
                      _shimmer.value.clamp(0.0, 1.0),
                      1.0,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.download_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Descargar gratis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismiss() {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Quizás más tarde',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String emoji;
  final String label;
  const _Feature({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _DividerVertical extends StatelessWidget {
  const _DividerVertical();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}
