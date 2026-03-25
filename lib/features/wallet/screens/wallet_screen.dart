import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.verdePrimario)),
      error: (_, __) => const Center(
          child: Text('Error al cargar',
              style: TextStyle(color: AppColors.textoSecundario))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final canCashout = user.coins >= AppConstants.minCashoutCoins;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saldo principal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2B1A), Color(0xFF0A1628)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.verdePrimario.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: AppColors.verdePrimario, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      '\$${user.balanceUsd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('${user.coins} monedas disponibles',
                        style: const TextStyle(
                            color: AppColors.textoSecundario, fontSize: 13)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canCashout
                            ? () => context.push(AppRoutes.cashout)
                            : null,
                        child: Text(canCashout
                            ? 'Solicitar cobro'
                            : 'Mínimo \$1.00 para cobrar'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Métodos de pago disponibles
              const Text('Métodos de cobro',
                  style: TextStyle(
                      color: AppColors.textoPrimario,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 12),
              _PaymentMethod(
                  icon: Icons.paypal_rounded,
                  name: 'PayPal',
                  desc: 'Internacional — mínimo \$1.00',
                  color: const Color(0xFF003087)),
              const SizedBox(height: 10),
              _PaymentMethod(
                  icon: Icons.account_balance_rounded,
                  name: 'MercadoPago',
                  desc: 'LatAm — mínimo \$1.00',
                  color: const Color(0xFF009EE3)),
              const SizedBox(height: 10),
              _PaymentMethod(
                  icon: Icons.store_rounded,
                  name: 'OXXO Pay',
                  desc: 'México — mínimo \$50 MXN',
                  color: const Color(0xFFE2001A)),
              const SizedBox(height: 10),
              _PaymentMethod(
                  icon: Icons.card_giftcard_rounded,
                  name: 'Gift Cards',
                  desc: 'Amazon, Steam, Google Play',
                  color: AppColors.dorado),
              const SizedBox(height: 24),
              // Historial
              const Text('Últimas transacciones',
                  style: TextStyle(
                      color: AppColors.textoPrimario,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 12),
              const Center(
                child: Text('Sin transacciones aún',
                    style: TextStyle(color: AppColors.textoSecundario)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentMethod extends StatelessWidget {
  final IconData icon;
  final String name;
  final String desc;
  final Color color;
  const _PaymentMethod(
      {required this.icon,
      required this.name,
      required this.desc,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textoDeshabilitado, size: 20),
        ],
      ),
    );
  }
}
