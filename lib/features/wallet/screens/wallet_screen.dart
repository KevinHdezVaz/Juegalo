import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_provider.dart';

// ── Provider: últimas 20 transacciones ───────────────────────────
final transactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];
  final rows = await Supabase.instance.client
      .from('transactions')
      .select()
      .eq('user_id', uid)
      .order('created_at', ascending: false)
      .limit(20);
  return List<Map<String, dynamic>>.from(rows);
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.azulPrimario)),
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
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.azulPrimario.withValues(alpha: 0.40),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      '\$${user.balanceUsd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('${user.coins} monedas disponibles',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canCashout
                            ? () => context.push(AppRoutes.cashout)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.azulOscuro,
                          elevation: 0,
                          disabledBackgroundColor: Colors.white30,
                          disabledForegroundColor: Colors.white60,
                        ),
                        child: Text(
                          canCashout ? 'Solicitar cobro' : 'Mínimo \$1.00 para cobrar',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
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
              ref.watch(transactionsProvider).when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.verdePrimario, strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
                data: (txs) => txs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Sin transacciones aún',
                              style: TextStyle(
                                  color: AppColors.textoSecundario)),
                        ),
                      )
                    : Column(
                        children: txs
                            .map((tx) => _TransactionRow(tx: tx))
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Fila de transacción ───────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount  = (tx['amount'] as int? ?? 0);
    final source  = tx['source'] as String? ?? '';
    final desc    = tx['description'] as String? ?? source;
    final isCredit = amount > 0;

    final icon = switch (source) {
      'video'   => Icons.play_circle_outline_rounded,
      'survey'  => Icons.assignment_outlined,
      'game'    => Icons.sports_esports_outlined,
      'cashout' => Icons.arrow_upward_rounded,
      'referral'=> Icons.people_outline_rounded,
      _         => Icons.monetization_on_outlined,
    };
    final color = isCredit ? AppColors.verdePrimario : AppColors.colorVideos;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(desc,
              style: const TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Text(
          '${isCredit ? '+' : ''}$amount',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
      ]),
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
