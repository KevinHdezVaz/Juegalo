import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _loading = false;

  Future<void> _signInGoogle() async {
    setState(() => _loading = true);
    try {
      await ref.read(userNotifierProvider.notifier).signInWithGoogle();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signInAnonymous() async {
    setState(() => _loading = true);
    try {
      await ref.read(userNotifierProvider.notifier).signInAnonymously();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              // Ícono
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: AppColors.verdePrimario.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.sports_esports_rounded,
                    size: 50, color: AppColors.verdePrimario),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Juega juegos, completa encuestas\ny gana dinero real',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Propuesta de valor
              _ValueRow(icon: Icons.sports_esports_rounded,
                  color: AppColors.colorJuegos,
                  text: 'Juega nuevos juegos y gana monedas'),
              const SizedBox(height: 14),
              _ValueRow(icon: Icons.assignment_outlined,
                  color: AppColors.colorEncuestas,
                  text: 'Completa encuestas rápidas'),
              const SizedBox(height: 14),
              _ValueRow(icon: Icons.play_circle_outline_rounded,
                  color: AppColors.colorVideos,
                  text: 'Mira videos y acumula monedas'),
              const SizedBox(height: 14),
              _ValueRow(icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.colorWallet,
                  text: 'Cobra por PayPal o MercadoPago'),
              const Spacer(),
              // Botones
              if (_loading)
                const CircularProgressIndicator(color: AppColors.verdePrimario)
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _signInGoogle,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                    label: const Text('Continuar con Google'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _signInAnonymous,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textoSecundario,
                      side: const BorderSide(color: AppColors.fondoCardBorde),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Jugar sin cuenta'),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _ValueRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.textoPrimario, fontSize: 14)),
        ),
      ],
    );
  }
}
