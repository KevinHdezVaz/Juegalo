import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/providers/cashout_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../home/widgets/daily_bonus_card.dart';
import '../../home/widgets/daily_goal_bar.dart';

// ── Provider: últimas 20 transacciones ───────────────────────────
final transactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
      error: (_, __) => Center(
          child: Text(context.l10n.walletErrorLoading,
              style: const TextStyle(color: AppColors.textoSecundario))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final canCashout = user.coins >= AppConstants.minCashoutCoins;

        return RefreshIndicator(
            color: AppColors.azulPrimario,
            onRefresh: () async {
              ref.invalidate(userProvider);
              ref.invalidate(transactionsProvider);
              ref.invalidate(cashoutRequestsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Meta diaria y bono ──────────────────────────────
                  DailyGoalBar(user: user),
                  const SizedBox(height: 10),
                  const DailyBonusCard(),
                  const SizedBox(height: 10),

                  // Saldo principal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1D4ED8),
                          Color(0xFF2563EB),
                          Color(0xFF3B82F6)
                        ],
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
                          '${user.balanceUsd.fmtUsd} USD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                            context.l10n
                                .walletCoinsAvailable(user.coins.formatted),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (canCashout) {
                                context.push(AppRoutes.cashout);
                              } else {
                                _showInsufficientCoinsDialog(
                                    context, user.coins);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.azulOscuro,
                              elevation: 0,
                            ),
                            child: Text(
                              canCashout
                                  ? context.l10n.walletRequestCashout
                                  : context.l10n.walletMinimumCashout,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Estado de solicitudes activas ───────────────────
                  ref.watch(cashoutRequestsProvider).when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (requests) {
                          if (requests.isEmpty) return const SizedBox.shrink();
                          return Column(
                            children: [
                              ...requests.map((r) => _CashoutStatusCard(
                                    request: r,
                                    referralBonusPaid: user.referralBonusPaid,
                                  )),
                              const SizedBox(height: 4),
                            ],
                          );
                        },
                      ),

                  const SizedBox(height: 4),
                  // Métodos de pago disponibles
                  Text(context.l10n.walletPaymentMethods,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  _PaymentMethod(
                      icon: Icons.paypal_rounded,
                      name: 'PayPal',
                      desc: context.l10n.walletPaypalDesc,
                      color: const Color(0xFF003087),
                      onTap: () {
                        if (canCashout) {
                          context.push(AppRoutes.cashout);
                        } else {
                          _showInsufficientCoinsDialog(context, user.coins);
                        }
                      }),
                  const SizedBox(height: 10),
                  _PaymentMethod(
                      icon: Icons.account_balance_rounded,
                      name: 'MercadoPago',
                      desc: context.l10n.walletMercadopagoDesc,
                      color: const Color(0xFF009EE3),
                      comingSoon: true,
                      onTap: null),
                  const SizedBox(height: 24),
                  // Historial
                  Text(context.l10n.walletTransactions,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  ref.watch(transactionsProvider).when(
                        loading: () => const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.verdePrimario,
                                strokeWidth: 2)),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (txs) => txs.isEmpty
                            ? Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(context.l10n.walletNoTransactions,
                                      style: const TextStyle(
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
            )); // cierra SingleChildScrollView y RefreshIndicator
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
    final amount = (tx['coins'] as int? ?? 0);
    final source = tx['source'] as String? ?? tx['type'] as String? ?? '';
    final desc = tx['description'] as String? ?? source;
    final isCredit = amount >= 0;

    final icon = switch (source) {
      'video' => Icons.play_circle_outline_rounded,
      'survey' => Icons.assignment_outlined,
      'game' => Icons.sports_esports_outlined,
      'cashout' => Icons.arrow_upward_rounded,
      'referral' => Icons.people_outline_rounded,
      'refund' => Icons.replay_rounded,
      'bonus' => Icons.star_outline_rounded,
      'migration' => Icons.swap_horiz_rounded,
      _ => Icons.monetization_on_outlined,
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
          width: 36,
          height: 36,
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
          '${isCredit ? '+' : ''}${amount.formatted}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 14),
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
  final VoidCallback? onTap;
  final bool comingSoon;
  const _PaymentMethod(
      {required this.icon,
      required this.name,
      required this.desc,
      required this.color,
      this.onTap,
      this.comingSoon = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fondoCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: (!comingSoon && onTap != null)
                  ? color.withValues(alpha: 0.3)
                  : AppColors.fondoCardBorde),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: comingSoon ? 0.06 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: comingSoon ? AppColors.textoDeshabilitado : color,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: comingSoon
                              ? AppColors.textoDeshabilitado
                              : AppColors.textoPrimario,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(comingSoon ? context.l10n.walletComingSoon : desc,
                      style: const TextStyle(
                          color: AppColors.textoSecundario, fontSize: 12)),
                ],
              ),
            ),
            if (comingSoon)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.fondoCardBorde,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(context.l10n.walletComingSoon,
                      style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)))
            else
              Icon(Icons.chevron_right,
                  color: onTap != null ? color : AppColors.textoDeshabilitado,
                  size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de seguimiento de solicitud ──────────────────────────
class _CashoutStatusCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool referralBonusPaid;
  const _CashoutStatusCard(
      {required this.request, this.referralBonusPaid = false});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final amountUsd = double.tryParse(request['amount_usd'].toString()) ?? 0.0;
    final method = request['method'] as String? ?? 'paypal';
    final account = request['payment_detail'] ?? request['account'] ?? '';
    final createdAt = DateTime.tryParse(request['created_at'] ?? '');

    final methodLabel = switch (method) {
      'paypal' => 'PayPal',
      'mercadopago' => 'MercadoPago',
      _ => method,
    };

    final isPaid = status == 'paid';

    // Definición de pasos
    final steps = [
      _Step(
        label: context.l10n.cashoutStepRequested,
        sublabel: context.l10n.cashoutStepRequestedSub,
        icon: Icons.send_rounded,
        done: true,
      ),
      _Step(
        label: context.l10n.cashoutStepReview,
        sublabel: context.l10n.cashoutStepReviewSub,
        icon: Icons.manage_search_rounded,
        done: status == 'processing' || isPaid,
        active: status == 'pending',
      ),
      _Step(
        label: context.l10n.cashoutStepProcessing,
        sublabel: context.l10n.cashoutStepProcessingSub,
        icon: Icons.payments_rounded,
        done: isPaid,
        active: status == 'processing',
      ),
      _Step(
        label: context.l10n.cashoutStepPaid,
        sublabel: context.l10n.cashoutStepPaidSub,
        icon: Icons.check_circle_rounded,
        done: isPaid,
        active: false,
      ),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: status == 'paid'
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : status == 'processing'
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                  : AppColors.fondoCardBorde,
          width: status == 'paid' || status == 'processing' ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.fondoElevado,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: Color(0xFF3B82F6), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.cashoutRequestHeader(amountUsd.fmtUsd, methodLabel),
                        style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (account.isNotEmpty)
                        Text(
                          account,
                          style: const TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Badge de estado
                _StatusPill(status: status),
              ],
            ),
          ),

          // ── Stepper ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Row(
              children: List.generate(steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  // Línea conectora
                  final stepIndex = i ~/ 2;
                  final lineActive = steps[stepIndex].done;
                  return Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: lineActive
                            ? const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)])
                            : null,
                        color: lineActive ? null : AppColors.fondoCardBorde,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                }
                final step = steps[i ~/ 2];
                return _StepDot(step: step);
              }),
            ),
          ),

          // ── Labels de pasos ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: steps.map((step) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        step.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: step.done
                              ? const Color(0xFF3B82F6)
                              : step.active
                                  ? AppColors.textoPrimario
                                  : const Color.fromARGB(255, 139, 139, 139),
                          fontSize: 10,
                          fontWeight: step.active || step.done
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.sublabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: step.active
                              ? const Color.fromARGB(255, 0, 0, 0)
                              : const Color.fromARGB(255, 66, 66, 66),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Banner pagado ─────────────────────────────────────────
          if (status == 'paid')
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(children: [
                const Text('🎉', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.cashoutPaidBanner,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      Text(context.l10n.cashoutPaidBannerSub,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ),

          // ── Banner bono de referido ───────────────────────────────
          if (referralBonusPaid)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1F8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF1A3FCC),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(children: [
                const Text('🎁', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.cashoutReferralBanner,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                      Text(context.l10n.cashoutReferralBannerSub,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ),

          // ── Nota de tiempo estimado ───────────────────────────────
          if (status == 'pending' || status == 'processing')
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: Color(0xFF3B82F6), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == 'pending'
                          ? context.l10n.cashoutTimePending
                          : context.l10n.cashoutTimeProcessing,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Fecha ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              status == 'paid' && request['processed_at'] != null
                  ? () {
                      final d =
                          DateTime.tryParse(request['processed_at'])?.toLocal();
                      if (d == null) return '';
                      return context.l10n.cashoutPaidOn(
                        '${d.day}/${d.month}/${d.year}',
                        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                      );
                    }()
                  : createdAt != null
                      ? context.l10n.cashoutRequestedOn(
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                          '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                        )
                      : '',
              style: const TextStyle(
                color: Color.fromARGB(255, 64, 64, 64),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool done;
  final bool active;
  const _Step({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.done,
    this.active = false,
  });
}

class _StepDot extends StatelessWidget {
  final _Step step;
  const _StepDot({required this.step});

  @override
  Widget build(BuildContext context) {
    if (step.done) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(step.icon, color: Colors.white, size: 14),
      );
    }
    if (step.active) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.fondoElevado,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF3B82F6), width: 2),
        ),
        child: Icon(step.icon, color: const Color(0xFF3B82F6), size: 14),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.fondoCardBorde, width: 1.5),
      ),
      child: Icon(step.icon, color: AppColors.textoDeshabilitado, size: 14),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      'pending' => (
          context.l10n.cashoutStatusPending,
          const Color(0xFFD97706),
          const Color(0xFF2D1B00)
        ),
      'processing' => (
          context.l10n.cashoutStatusProcessing,
          const Color(0xFF3B82F6),
          const Color(0xFF0D1F3C)
        ),
      'paid' => (
          context.l10n.cashoutStatusPaid,
          const Color(0xFF10B981),
          const Color(0xFF022C22)
        ),
      'rejected' => (
          context.l10n.cashoutStatusRejected,
          const Color(0xFFEF4444),
          const Color(0xFF2D0A0A)
        ),
      _ => ('—', AppColors.textoSecundario, AppColors.fondoElevado),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

void _showInsufficientCoinsDialog(BuildContext context, int currentCoins) {
  final needed = AppConstants.minCashoutCoins - currentCoins;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.fondoElevado,
      title: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.azulPrimario),
          const SizedBox(width: 10),
          Text(context.l10n.walletAlmostThere,
              style: const TextStyle(
                  color: AppColors.textoPrimario, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(
        context.l10n.walletNeedCoins(
          AppConstants.minCashoutCoins.formatted,
          (needed > 0 ? needed : 0).formatted,
        ),
        style: const TextStyle(color: AppColors.textoSecundario),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.walletGotIt,
              style: const TextStyle(
                  color: AppColors.azulPrimario, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
