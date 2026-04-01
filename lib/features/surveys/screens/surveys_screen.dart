import 'package:cpx_research_sdk_flutter/cpx.dart';
import 'package:cpx_research_sdk_flutter/model/cpx_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/helpers/daily_bonus_helper.dart';

class SurveysScreen extends ConsumerStatefulWidget {
  const SurveysScreen({super.key});

  @override
  ConsumerState<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends ConsumerState<SurveysScreen> {
  final CPXData _cpxData = CPXData.cpxData;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    // Escuchar transacciones completadas → acreditar monedas
    _cpxData.transactions.addListener(_onTransactions);
    // Fetch inicial (CPXResearch en HomeScreen ya arranca el timer,
    // pero hacemos uno manual para respuesta inmediata al entrar al tab)
    fetchCPXSurveysAndTransactions();
    _lastUpdated = DateTime.now();
  }

  @override
  void dispose() {
    _cpxData.transactions.removeListener(_onTransactions);
    super.dispose();
  }

  // ── Listener de transacciones ─────────────────────────────────────
  void _onTransactions() {
    final txs = _cpxData.transactions.value;
    if (txs == null || txs.isEmpty) return;
    for (final tx in txs) {
      _creditCoins(
        transactionId: tx.transactionID ?? '',
        messageId: tx.messageID ?? '',
        earningsGross: tx.verdienstUserLocalMoney ?? '0',
      );
    }
  }

  Future<void> _creditCoins({
    required String transactionId,
    required String messageId,
    required String earningsGross,
  }) async {
    if (transactionId.isEmpty) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.rpc('credit_coins', params: {
        'p_user_id': uid,
        'p_coins': AppConstants.coinsPerSurvey,
        'p_source': 'survey',
        'p_description': 'Encuesta CPX completada (\$$earningsGross)',
      });
      // Marcar como pagada para no procesar de nuevo
      markTransactionAsPaid(transactionId, messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '+${AppConstants.coinsPerSurvey} monedas — encuesta completada',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.verdePrimario,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
        await tryClaimDailyBonus(context, ref);
      }
    } catch (e) {
      debugPrint('❌ credit_coins (survey): $e');
    }
  }

  void _refresh() {
    fetchCPXSurveysAndTransactions();
    setState(() => _lastUpdated = DateTime.now());
  }

  String _timeAgo() {
    if (_lastUpdated == null) return '';
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    return 'hace ${diff.inHours}h';
  }

  // ── Builder personalizado para cada tarjeta de encuesta ──────────
  Widget _surveyCardBuilder(
    List<Survey> surveys,
    CPXCardConfig config,
    CPXText? text,
  ) {
    if (surveys.isEmpty) {
      return _EmptyState(onRefresh: _refresh);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: surveys.length,
      itemBuilder: (context, i) => _SurveyCard(
        survey: surveys[i],
        text: text,
        onTap: () => showCPXBrowserOverlay(surveys[i].id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.azulPrimario,
      onRefresh: () async => _refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.textoPrimario.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.textoPrimario,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Encuestas disponibles',
                        style: TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      ValueListenableBuilder<List<Survey>?>(
                        valueListenable: _cpxData.surveys,
                        builder: (_, surveys, __) {
                          final count = surveys?.length ?? 0;
                          return Text(
                            count > 0
                                ? '$count ${count == 1 ? 'encuesta' : 'encuestas'} • ${_timeAgo()}'
                                : 'Actualizado ${_timeAgo()}',
                            style: const TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Botón refresh
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textoPrimario,
                  ),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Banner informativo ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.textoPrimario.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textoPrimario.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: AppColors.dorado,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                        ),
                        children: [
                          const TextSpan(text: 'Ganas '),
                          TextSpan(
                            text: '+${AppConstants.coinsPerSurvey} monedas',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.verdePrimario,
                            ),
                          ),
                          const TextSpan(text: ' por cada encuesta completada'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Lista de encuestas ────────────────────────────────────
            CPXSurveyCards(
              config: CPXCardConfig(
                accentColor: AppColors.azulClaro,
                cardBackgroundColor: AppColors.fondoCard,
                textColor: AppColors.textoPrimario,
                starColor: AppColors.dorado,
                inactiveStarColor: AppColors.fondoCardBorde,
                payoutColor: AppColors.verdePrimario,
                cardCount: 3,
              ),
              hideIfEmpty: false,
              padding: EdgeInsets.zero,
              noSurveysWidget: _EmptyState(onRefresh: _refresh),
              builder: _surveyCardBuilder,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta individual de encuesta ────────────────────────────────────
class _SurveyCard extends StatelessWidget {
  final Survey survey;
  final CPXText? text;
  final VoidCallback onTap;

  const _SurveyCard({
    required this.survey,
    required this.text,
    required this.onTap,
  });

  Widget _stars(int avg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          Icons.star_rounded,
          size: 13,
          color: i < avg ? AppColors.dorado : AppColors.fondoCardBorde,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payout = survey.payout ?? '?';
    final payoutOriginal = survey.payoutOriginal;
    final loi = survey.loi?.toString() ?? '?';
    final avg = survey.statisticsRatingAvg ?? 0;
    final currency = text?.currency_name_plural ?? 'Monedas';
    final minLabel = text?.shortcurt_min ?? 'min';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fondoCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fondoCardBorde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono de encuesta
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.azulClaro.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.azulClaro,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pago
                  Row(
                    children: [
                      if (payoutOriginal != null) ...[
                        Text(
                          payoutOriginal,
                          style: const TextStyle(
                            color: AppColors.textoDeshabilitado,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        payout,
                        style: TextStyle(
                          color: payoutOriginal != null
                              ? AppColors.verdePrimario
                              : AppColors.textoPrimario,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currency,
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Duración + estrellas
                  Row(
                    children: [
                      const Icon(
                        Icons.watch_later_outlined,
                        size: 13,
                        color: AppColors.textoSecundario,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$loi $minLabel',
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _stars(avg),
                    ],
                  ),
                ],
              ),
            ),

            // Flecha
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.textoPrimario.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textoPrimario,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado vacío ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.textoPrimario.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppColors.textoPrimario,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay encuestas disponibles',
              style: TextStyle(
                color: AppColors.textoPrimario,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vuelve más tarde o toca actualizar',
              style: TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textoPrimario),
              label: const Text(
                'Actualizar',
                style: TextStyle(color: AppColors.textoPrimario),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.textoPrimario),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
