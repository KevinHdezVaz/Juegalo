import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_provider.dart';
import '../../tutorial/screens/tutorial_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  bool _loading     = false;
  bool _showRefCode = false;
  final _refCtrl    = TextEditingController();
  late AnimationController _anim;
  late Animation<double>   _fadeIn;
  late Animation<Offset>   _slideUp;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  String get _refCode => _refCtrl.text.trim().toUpperCase();

  Future<void> _afterLogin() async {
    final done = await isTutorialCompleted();
    if (!mounted) return;
    context.go(done ? AppRoutes.home : AppRoutes.tutorial);
  }

  Future<void> _signInGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(userNotifierProvider.notifier)
          .signInWithGoogle(referralCode: _refCode.isNotEmpty ? _refCode : null);
      await _afterLogin();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                  referralCode: _refCode.isNotEmpty ? _refCode : null,
                );
            await _afterLogin();
          } catch (e) {
            setState(() => _loading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Correo o contraseña incorrectos'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
      ),
    );
  }

  Future<void> _signInApple() async {
    setState(() => _loading = true);
    try {
      await ref.read(userNotifierProvider.notifier)
          .signInWithApple(referralCode: _refCode.isNotEmpty ? _refCode : null);
      await _afterLogin();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _signInAnonymous() async {
    setState(() => _loading = true);
    try {
      await ref.read(userNotifierProvider.notifier)
          .signInAnonymously(referralCode: _refCode.isNotEmpty ? _refCode : null);
      await _afterLogin();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.azulPrimario,
      body: Stack(
        children: [
          // ── Fondo degradado ──────────────────────────────────
          Container(
            height: h * 0.52,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A3FCC), Color(0xFF2563EB), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Círculos decorativos ─────────────────────────────
          Positioned(
            top: -60, right: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 40, left: -80,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // ── Contenido principal ──────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Hero section ──────────────────────────────
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 90, height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/icons/app_icon.png',
                                width: 90, height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Título
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Juega. Gana. Cobra.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Stats badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on_rounded,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '+\$12,847 pagados a usuarios',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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

                // ── Tarjeta inferior ───────────────────────────
                Expanded(
                  flex: 7,
                  child: SlideTransition(
                    position: _slideUp,
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32)),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle
                              Center(
                                child: Container(
                                  width: 40, height: 4,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: AppColors.fondoCardBorde,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),

                              // Propuestas de valor — chips horizontales
                              const Text(
                                '¿Cómo funciona?',
                                style: TextStyle(
                                  color: AppColors.textoPrimario,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(children: [
                                _FeatureChip(
                                    icon: Icons.sports_esports_rounded,
                                    label: 'Juegos',
                                    color: AppColors.colorJuegos),
                                const SizedBox(width: 8),
                                _FeatureChip(
                                    icon: Icons.assignment_outlined,
                                    label: 'Encuestas',
                                    color: AppColors.colorEncuestas),
                                const SizedBox(width: 8),
                                _FeatureChip(
                                    icon: Icons.play_circle_outline_rounded,
                                    label: 'Videos',
                                    color: AppColors.colorVideos),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                _FeatureChip(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: 'PayPal / MP',
                                    color: AppColors.azulPrimario),
                                const SizedBox(width: 8),
                                _FeatureChip(
                                    icon: Icons.leaderboard_rounded,
                                    label: 'Ranking',
                                    color: AppColors.dorado),
                                const SizedBox(width: 8),
                                _FeatureChip(
                                    icon: Icons.local_fire_department_rounded,
                                    label: 'Racha x2',
                                    color: Colors.orange),
                              ]),

                              const SizedBox(height: 20),

                              // Código referido
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _showRefCode = !_showRefCode),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.card_giftcard_rounded,
                                      color: AppColors.dorado, size: 16),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '¿Tienes un código de referido?',
                                      style: TextStyle(
                                        color: AppColors.textoSecundario,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      _showRefCode
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      color: AppColors.textoSecundario,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),

                              if (_showRefCode) ...[
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _refCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.dorado,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 5,
                                    fontSize: 20,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'XXXXXXXX',
                                    hintStyle: const TextStyle(
                                        color: AppColors.textoDeshabilitado,
                                        letterSpacing: 3,
                                        fontSize: 16),
                                    filled: true,
                                    fillColor: const Color(0xFFFFFBEB),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: AppColors.dorado
                                              .withValues(alpha: 0.4)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: AppColors.dorado
                                              .withValues(alpha: 0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.dorado, width: 2),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // ── Botones ──────────────────────
                              if (_loading)
                                const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.azulPrimario),
                                )
                              else ...[
                                // 1. Google
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _signInGoogle,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.azulPrimario,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 26, height: 26,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Center(
                                            child: Text('G',
                                                style: TextStyle(
                                                    color: Color(0xFF4285F4),
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('Continuar con Google',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 2. Apple (solo en iOS)
                                if (Platform.isIOS) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: _signInApple,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.apple, size: 22, color: Colors.white),
                                          SizedBox(width: 10),
                                          Text('Continuar con Apple',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // 3. Correo — abre dialog
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: _openEmailDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textoPrimario,
                                      side: const BorderSide(
                                          color: AppColors.fondoCardBorde,
                                          width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.email_outlined, size: 20),
                                        SizedBox(width: 10),
                                        Text('Continuar con correo',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // 3. Anónimo — al fondo, menos prominente
                                Center(
                                  child: GestureDetector(
                                    onTap: _signInAnonymous,
                                    child: const Text(
                                      'Jugar sin cuenta',
                                      style: TextStyle(
                                        color: AppColors.textoSecundario,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Legal
                              Center(
                                child: Text(
                                  'Al continuar aceptas los Términos de uso\ny la Política de privacidad',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textoDeshabilitado,
                                    fontSize: 11,
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

// ── Dialog de login con correo ────────────────────────────────────
class _EmailLoginDialog extends StatefulWidget {
  final Future<void> Function(String email, String password) onLogin;
  const _EmailLoginDialog({required this.onLogin});

  @override
  State<_EmailLoginDialog> createState() => _EmailLoginDialogState();
}

class _EmailLoginDialogState extends State<_EmailLoginDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  bool _loading    = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _loading = true);
    await widget.onLogin(email, pass);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Iniciar sesión',
                          style: TextStyle(
                              color: AppColors.textoPrimario,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text('Correo y contraseña',
                          style: TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textoSecundario, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Correo
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                  color: AppColors.textoPrimario, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                labelStyle: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 13),
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AppColors.textoSecundario, size: 18),
                filled: true,
                fillColor: AppColors.fondoPrincipal,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.fondoCardBorde)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.fondoCardBorde)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.azulPrimario, width: 1.5)),
              ),
            ),
            const SizedBox(height: 12),

            // Contraseña
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                  color: AppColors.textoPrimario, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                labelStyle: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 13),
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textoSecundario, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textoSecundario,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                filled: true,
                fillColor: AppColors.fondoPrincipal,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.fondoCardBorde)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.fondoCardBorde)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.azulPrimario, width: 1.5)),
              ),
            ),
            const SizedBox(height: 20),

            // Botón entrar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulPrimario,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.azulPrimario.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Entrar',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip de característica ────────────────────────────────────────
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _FeatureChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
