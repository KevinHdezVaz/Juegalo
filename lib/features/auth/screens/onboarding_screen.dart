import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/providers/user_provider.dart';
import '../../tutorial/screens/tutorial_screen.dart';

// ─────────────────────────────────────────────────────────────────
// Coin particle data
// ─────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  bool _loading = false;

  late AnimationController _entryCtrl;
  late AnimationController _coinsCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _featuresCtrl;

  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _logoFloat;
  late List<Animation<Offset>> _featureSlides;
  late List<Animation<double>> _featureFades;
  late final List<_CoinData> _coins;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();

    const emojis = ['🪙', '🪙', '🪙', '💰', '⭐', '🪙', '🪙', '🪙'];
    _coins = List.generate(
        22,
        (i) => _CoinData(
              x: rng.nextDouble(),
              phaseOffset: rng.nextDouble(),
              size: 14 + rng.nextDouble() * 16,
              opacity: 0.35 + rng.nextDouble() * 0.45,
              rotationDir: rng.nextBool() ? 1.0 : -1.0,
              speed: 0.12 + rng.nextDouble() * 0.18,
              emoji: emojis[rng.nextInt(emojis.length)],
            ));

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _coinsCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
          ..repeat();

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _logoFloat = Tween<double>(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _featuresCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _featureSlides = List.generate(3, (i) {
      final start = i * 0.20;
      final end = (start + 0.65).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0.4, 0), end: Offset.zero)
          .animate(
        CurvedAnimation(
            parent: _featuresCtrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic)),
      );
    });
    _featureFades = List.generate(3, (i) {
      final start = i * 0.20;
      final end = (start + 0.65).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _featuresCtrl,
            curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 380), () {
      if (mounted) _featuresCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _coinsCtrl.dispose();
    _floatCtrl.dispose();
    _featuresCtrl.dispose();
    super.dispose();
  }

  Future<void> _afterLogin() async {
    if (!mounted) return;
    final done = await isTutorialCompleted();
    if (!mounted) return;
    context.go(done ? AppRoutes.home : AppRoutes.tutorial);
  }

  Future<void> _signInGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(userNotifierProvider.notifier).signInWithGoogle();
      await _afterLogin();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError('Error: $e');
    }
  }

  Future<void> _openEmailDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => _EmailLoginDialog(
        onLogin: (email, password) async {
          Navigator.of(ctx).pop();
          setState(() => _loading = true);
          try {
            await ref.read(userNotifierProvider.notifier).signInWithEmail(
                  email: email,
                  password: password,
                );
            await _afterLogin();
          } catch (e) {
            setState(() => _loading = false);
            if (mounted) _showError(context.l10n.onboardingErrorWrongCredentials);
          }
        },
        onSignUp: (email, password) async {
          Navigator.of(ctx).pop();
          setState(() => _loading = true);
          try {
            await ref.read(userNotifierProvider.notifier).signUpWithEmail(
                  email: email,
                  password: password,
                );
            await _afterLogin();
          } catch (e) {
            setState(() => _loading = false);
            if (mounted) _showError('Error al crear cuenta: ${e.toString()}');
          }
        },
      ),
    );
  }

  Future<void> _signInApple() async {
    setState(() => _loading = true);
    try {
      await ref.read(userNotifierProvider.notifier).signInWithApple();
      await _afterLogin();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError('Error: $e');
    }
  }

  Future<void> _signInAnonymous() async {
    setState(() => _loading = true);
    try {
      await ref.read(userNotifierProvider.notifier).signInAnonymously();
      await _afterLogin();
    } catch (e) {
      setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('🔴 [OnboardingScreen] Error en _signInAnonymous: $e');
      if (mounted) _showError(context.l10n.onboardingErrorGeneric(msg));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2A9A),
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1F8A),
                  Color(0xFF1A3FCC),
                  Color(0xFF2563EB)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Falling coins ────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final w = constraints.maxWidth;
              return AnimatedBuilder(
                animation: _coinsCtrl,
                builder: (_, __) => Stack(
                  children: _coins.map((coin) {
                    final phase =
                        (_coinsCtrl.value * coin.speed + coin.phaseOffset) %
                            1.0;
                    final x = coin.x * w - coin.size / 2;
                    final y = -coin.size * 2 + (h + coin.size * 3) * phase;
                    double alpha = coin.opacity;
                    if (phase < 0.06) alpha *= phase / 0.06;
                    if (phase > 0.88) alpha *= (1.0 - phase) / 0.12;
                    final angle = phase * math.pi * 2.0 * coin.rotationDir;
                    return Positioned(
                      left: x,
                      top: y,
                      child: Opacity(
                        opacity: alpha.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: angle,
                          child: coin.emoji == '🪙'
                              ? Icon(Icons.monetization_on, color: Colors.amber, size: coin.size)
                              : Text(coin.emoji, style: TextStyle(fontSize: coin.size, height: 1)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // ── Decorative circles ───────────────────────────────────
          Positioned(
              top: -80,
              right: -50,
              child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05)))),
          Positioned(
              top: 50,
              left: -90,
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04)))),
          Positioned(
              top: 160,
              right: 20,
              child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.06)))),

          // ── Main content ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── HERO ──────────────────────────────────────────
                Expanded(
                  flex: 46,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Floating app icon
                          AnimatedBuilder(
                            animation: _logoFloat,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _logoFloat.value),
                              child: child,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.40),
                                    blurRadius: 36,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.30),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.asset(
                                  'assets/icons/app_icon.png',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // App name
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.onboardingTagline,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Social proof badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Stars
                                const Text('⭐⭐⭐⭐⭐',
                                    style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 14,
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.onboardingPaidBadge,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── CARD ──────────────────────────────────────────
                Expanded(
                  flex: 54,
                  child: SlideTransition(
                    position: _slideUp,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.fondoPrincipal,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Handle
                              Center(
                                child: Container(
                                  width: 36,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.fondoCardBorde,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),

                              // Section title
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.azulPrimario,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.onboardingHowItWorks,
                                    style: const TextStyle(
                                      color: AppColors.textoPrimario,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Feature rows (staggered)
                              ...List.generate(3, (i) {
                                final features = [
                                  (
                                    num: '1',
                                    emoji: '🎮',
                                    title: context.l10n.onboardingFeaturePlay,
                                    subtitle: context.l10n.onboardingFeaturePlaySubtitle,
                                    color: AppColors.colorJuegos,
                                  ),
                                  (
                                    num: '2',
                                    emoji: '📋',
                                    title: context.l10n.onboardingFeatureSurveys,
                                    subtitle: context.l10n.onboardingFeatureSurveysSubtitle,
                                    color: AppColors.colorEncuestas,
                                  ),
                                  (
                                    num: '3',
                                    emoji: '💸',
                                    title: context.l10n.onboardingFeatureCashout,
                                    subtitle: context.l10n.onboardingFeatureCashoutSubtitle,
                                    color: AppColors.verdePrimario,
                                  ),
                                ];
                                final f = features[i];
                                return SlideTransition(
                                  position: _featureSlides[i],
                                  child: FadeTransition(
                                    opacity: _featureFades[i],
                                    child: _FeatureRow(
                                      number: f.num,
                                      emoji: f.emoji,
                                      title: f.title,
                                      subtitle: f.subtitle,
                                      color: f.color,
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 4),

                              // Divider con texto
                              _Divider(label: context.l10n.onboardingStartNow),
                              const SizedBox(height: 10),

                              // ── Botones ────────────────────────
                              if (_loading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: CircularProgressIndicator(
                                        color: AppColors.azulPrimario),
                                  ),
                                )
                              else ...[
                                // Google
                                _AuthButton(
                                  onTap: _signInGoogle,
                                  backgroundColor: AppColors.azulPrimario,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: SvgPicture.asset(
                                          'assets/icons/google_logo.svg',
                                          width: 18,
                                          height: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(context.l10n.onboardingContinueGoogle,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Apple (iOS only)
                                if (Platform.isIOS) ...[
                                  _AuthButton(
                                    onTap: _signInApple,
                                    backgroundColor: const Color(0xFF1C1C1E),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.apple,
                                            size: 22, color: Colors.white),
                                        const SizedBox(width: 10),
                                        Text(context.l10n.onboardingContinueApple,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],

                                // Separador
                                _OrDivider(),
                                const SizedBox(height: 8),

                                // Email
                                _AuthButton(
                                  onTap: _openEmailDialog,
                                  backgroundColor: Colors.white,
                                  border: Border.all(
                                      color: AppColors.fondoCardBorde,
                                      width: 1.5),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.email_outlined,
                                          size: 20,
                                          color: AppColors.textoPrimario),
                                      const SizedBox(width: 10),
                                      Text(context.l10n.onboardingContinueEmail,
                                          style: const TextStyle(
                                              color: AppColors.textoPrimario,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Jugar sin cuenta
                                _AuthButton(
                                  onTap: _signInAnonymous,
                                  backgroundColor: Colors.transparent,
                                  border: Border.all(
                                      color: AppColors.textoDeshabilitado,
                                      width: 1.2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_circle_outline_rounded,
                                          size: 20,
                                          color: AppColors.textoSecundario),
                                      const SizedBox(width: 8),
                                      Text(context.l10n.onboardingPlayGuest,
                                          style: TextStyle(
                                              color: AppColors.textoSecundario,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // Legal
                              Center(
                                child: Text(
                                  context.l10n.onboardingLegal,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textoDeshabilitado,
                                    fontSize: 10.5,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Feature row (horizontal)
// ─────────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String number;
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureRow({
    required this.number,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Row(
        children: [
          // Number badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Emoji
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Auth button
// ─────────────────────────────────────────────────────────────────
class _AuthButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Widget child;
  final BoxBorder? border;

  const _AuthButton({
    required this.onTap,
    required this.backgroundColor,
    required this.child,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: border,
          boxShadow: backgroundColor != Colors.transparent
              ? [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Dividers
// ─────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.fondoCardBorde, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.fondoCardBorde, height: 1)),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.fondoCardBorde, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            AppLocalizations.of(context)?.onboardingOr ?? 'o',
            style: const TextStyle(
              color: AppColors.textoDeshabilitado,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.fondoCardBorde, height: 1)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Email login / register dialog
// ─────────────────────────────────────────────────────────────────
class _EmailLoginDialog extends StatefulWidget {
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function(String email, String password) onSignUp;
  const _EmailLoginDialog({required this.onLogin, required this.onSignUp});

  @override
  State<_EmailLoginDialog> createState() => _EmailLoginDialogState();
}

class _EmailLoginDialogState extends State<_EmailLoginDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _emailCtrl      = TextEditingController();
  final _passCtrl       = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _obscure        = true;
  bool _obscureConfirm = true;
  bool _loading        = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onLogin(email, pass);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submitSignUp() async {
    final email   = _emailCtrl.text.trim();
    final pass    = _passCtrl.text;
    final confirm = _passConfirmCtrl.text;
    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) return;
    if (pass != confirm) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Mínimo 6 caracteres');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onSignUp(email, pass);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffix}) =>
    InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textoSecundario, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textoSecundario, size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.fondoPrincipal,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fondoCardBorde)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fondoCardBorde)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.azulPrimario, width: 1.5)),
    );

  @override
  Widget build(BuildContext context) {
    final isLogin = _tabCtrl.index == 0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.azulPrimario.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.email_outlined,
                      color: AppColors.azulPrimario, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Correo electrónico',
                      style: TextStyle(color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textoSecundario, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Tabs ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.fondoPrincipal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.azulPrimario,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textoSecundario,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Iniciar sesión'),
                  Tab(text: 'Crear cuenta'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Campos ──────────────────────────────────────────
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.textoPrimario, fontSize: 14),
              decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
              onSubmitted: isLogin ? (_) => _submitLogin() : null,
              style: const TextStyle(color: AppColors.textoPrimario, fontSize: 14),
              decoration: _inputDecoration('Contraseña', Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textoSecundario, size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

            // ── Confirmar contraseña (solo en registro) ──────────
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _tabCtrl.index == 1
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _passConfirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitSignUp(),
                      style: const TextStyle(color: AppColors.textoPrimario, fontSize: 14),
                      decoration: _inputDecoration('Confirmar contraseña', Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textoSecundario, size: 18),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            ),

            // ── Error ────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],

            const SizedBox(height: 20),

            // ── Botón ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null
                    : (isLogin ? _submitLogin : _submitSignUp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrimario,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.azulPrimario.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(isLogin ? 'Entrar' : 'Crear cuenta',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
