import 'dart:io';
import 'package:cpx_research_sdk_flutter/cpx.dart';
import 'package:cpx_research_sdk_flutter/model/cpx_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/helpers/daily_bonus_helper.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/providers/feature_flags_provider.dart';
import '../../../shared/widgets/feature_disabled_screen.dart';

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
    // Fetch inicial — si CPXResearch aún no montó, el guard en
    // CPXNetworkService lo ignora silenciosamente y lo hará él mismo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fetchCPXSurveysAndTransactions();
      _lastUpdated = DateTime.now();
    });
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

    // ── El postback server-side (CPX → /api/postback/cpx) ya acreditó ──────
    // las monedas reales. Flutter solo marca como pagada y refresca la UI.
    // NO llamamos credit_coins directamente para evitar doble crédito.
    markTransactionAsPaid(transactionId, messageId);

    // Calcular monedas reales con la misma fórmula del servidor
    // (CPX_COINS_DIVISOR=2, CPX_COINS_MAX=5000, CPX_COINS_MIN=100)
    final rawCoins = double.tryParse(earningsGross) ?? 0.0;
    final earnedCoins = (rawCoins / AppConstants.cpxCoinsDivisor)
        .floor()
        .clamp(AppConstants.cpxCoinsMin, AppConstants.cpxCoinsMax);

    // Esperar brevemente a que el postback procese antes de refrescar
    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;

    ref.invalidate(userProvider);
    ref.invalidate(userNotifierProvider);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        // ignore: use_build_context_synchronously
        context.l10n.surveysCoinsEarned(earnedCoins.formatted),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      backgroundColor: AppColors.verdePrimario,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));

    // ignore: use_build_context_synchronously
    await tryClaimDailyBonus(context, ref);
    if (!context.mounted) return;
    // ignore: use_build_context_synchronously
    await tryClaimDailyGoalBonus(context, ref);
  }

  Future<void> _refresh() async {
    fetchCPXSurveysAndTransactions();
    await ref.read(userNotifierProvider.notifier).refreshUser();
    setState(() => _lastUpdated = DateTime.now());
  }

  String _timeAgo(BuildContext context) {
    if (_lastUpdated == null) return '';
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inSeconds < 60) {
      return context.l10n.surveysTimeAgoSeconds(diff.inSeconds);
    }
    if (diff.inMinutes < 60) {
      return context.l10n.surveysTimeAgoMinutes(diff.inMinutes);
    }
    return context.l10n.surveysTimeAgoHours(diff.inHours);
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
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    if (flags != null && !flags.surveysEnabled) {
      return FeatureDisabledScreen(
        title: context.l10n.surveysMaintenance,
        subtitle: context.l10n.surveysMaintenanceSub,
        icon: Icons.poll_rounded,
        theme: FeatureTheme.surveys,
      );
    }

    return RefreshIndicator(
      color: AppColors.azulPrimario,
      onRefresh: () async => _refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Promo banners en row (Winner + MusicMeet) ────────────
            const Row(
              children: [
                Expanded(child: _WinnerPromoBanner()),
                SizedBox(width: 10),
                Expanded(child: _PromoAppBanner()),
              ],
            ),
            const SizedBox(height: 16),

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
                      Text(
                        context.l10n.surveysTitle,
                        style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      ValueListenableBuilder<List<Survey>?>(
                        valueListenable: _cpxData.surveys,
                        builder: (ctx, surveys, __) {
                          final count = surveys?.length ?? 0;
                          return Text(
                            count > 0
                                ? (count == 1
                                    ? ctx.l10n
                                        .surveysCount(count, _timeAgo(ctx))
                                    : ctx.l10n.surveysCountPlural(
                                        count, _timeAgo(ctx)))
                                : ctx.l10n.surveysUpdated(_timeAgo(ctx)),
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
                  tooltip: context.l10n.surveysRefresh,
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
                          TextSpan(text: context.l10n.surveysEarn),
                          TextSpan(
                            text:
                                '+${AppConstants.cpxCoinsMin.formatted}–${AppConstants.cpxCoinsMax.formatted} monedas',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.verdePrimario,
                            ),
                          ),
                          TextSpan(text: context.l10n.surveysPerSurvey),
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

// ── Banner promocional Winner (app del mismo creador) ────────────────
class _WinnerPromoBanner extends StatelessWidget {
  const _WinnerPromoBanner();

  static const _urlAndroid =
      'https://play.google.com/store/apps/details?id=com.kevinGame.winner&hl=es_MX';
  static const _urlIos =
      'https://apps.apple.com/us/app/winner-gana-dinero-jugando/id6769851325';
  static const _iconUrl =
      'https://play-lh.googleusercontent.com/Ye_p03ap5KbWGKUeTXf82_1ihiuSe9SElq_a7zjOHyO1NpTgd_B25M2rPJQvjncaEAF2BFatbfjxARJDDlIS=w240-h480';

  Future<void> _openStore() async {
    final uri = Uri.parse(Platform.isIOS ? _urlIos : _urlAndroid);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openStore,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _iconUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 42,
                  height: 42,
                  color: const Color(0xFF065F46),
                  child: const Icon(Icons.attach_money_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Winner',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    'Gana en PayPal',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF059669),
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner promocional MusicMeet ──────────────────────────────────────
class _PromoAppBanner extends StatelessWidget {
  const _PromoAppBanner();

  static const _androidUrl =
      'https://play.google.com/store/apps/details?id=com.musicapp.app_music_comunidad';
  static const _iosUrl =
      'https://apps.apple.com/mx/app/musicmeet-conecta-por-m%C3%BAsica/id6762303211';

  Future<void> _openStore() async {
    final uri = Uri.parse(Platform.isIOS ? _iosUrl : _androidUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openStore,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logoMusicMeet.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MusicMeet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    'Conecta por música',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF9333EA),
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
            Text(
              context.l10n.surveysEmpty,
              style: const TextStyle(
                color: AppColors.textoPrimario,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.surveysEmptySubtitle,
              style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textoPrimario),
              label: Text(
                context.l10n.surveysRefresh,
                style: const TextStyle(color: AppColors.textoPrimario),
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
