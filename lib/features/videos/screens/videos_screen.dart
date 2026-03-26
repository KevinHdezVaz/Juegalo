import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/helpers/daily_bonus_helper.dart';

// ── Test IDs (reemplazar con reales cuando tengas cuenta AdMob) ──
const _rewardedAdUnitId = String.fromEnvironment(
  'ADMOB_REWARDED_ID',
  defaultValue: 'ca-app-pub-3940256099942544/5224354917', // test
);

const _kVideosKey = 'videos_watched_today';
const _kVideosDateKey = 'videos_watched_date';

// ── Provider: cuántos videos ha visto hoy ───────────────────────
final videosWatchedProvider = StateProvider<int>((ref) => 0);

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _adLoaded  = false;

  @override
  void initState() {
    super.initState();
    _loadDailyCount();
    _loadAd();
  }

  // ── Carga el contador diario desde SharedPreferences ────────
  Future<void> _loadDailyCount() async {
    final p    = await SharedPreferences.getInstance();
    final date = p.getString(_kVideosDateKey) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (date != today) {
      // Nuevo día: resetea contador
      await p.setInt(_kVideosKey, 0);
      await p.setString(_kVideosDateKey, today);
      ref.read(videosWatchedProvider.notifier).state = 0;
    } else {
      ref.read(videosWatchedProvider.notifier).state =
          p.getInt(_kVideosKey) ?? 0;
    }
  }

  // ── Carga el anuncio rewarded ────────────────────────────────
  void _loadAd() {
    setState(() { _isLoading = true; _adLoaded = false; });

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          setState(() { _isLoading = false; _adLoaded = true; });
        },
        onAdFailedToLoad: (error) {
          setState(() { _isLoading = false; _adLoaded = false; });
        },
      ),
    );
  }

  // ── Muestra el anuncio y acredita monedas al completarlo ─────
  Future<void> _showAd() async {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadAd(); // pre-carga el siguiente
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, reward) async {
        await _creditCoins();
      },
    );
  }

  // ── Acredita monedas en Supabase ─────────────────────────────
  Future<void> _creditCoins() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await Supabase.instance.client.rpc('credit_coins', params: {
        'p_user_id'    : uid,
        'p_coins'      : AppConstants.coinsPerVideo,
        'p_source'     : 'video',
        'p_description': 'Video completado',
      });

      // Actualiza contador local
      final p     = await SharedPreferences.getInstance();
      final count = (p.getInt(_kVideosKey) ?? 0) + 1;
      await p.setInt(_kVideosKey, count);
      ref.read(videosWatchedProvider.notifier).state = count;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '+${AppConstants.coinsPerVideo} monedas ganadas',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.verdePrimario,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        // Auto-reclama el bono diario si aún no fue reclamado
        await tryClaimDailyBonus(context, ref);
      }
    } catch (e) {
      debugPrint('❌ credit_coins error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al acreditar monedas: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watched = ref.watch(videosWatchedProvider);
    final maxVideos = AppConstants.coinsPerVideoMax;
    final limitReached = watched >= maxVideos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header de progreso diario ──────────────────────────
          _DailyProgressCard(watched: watched, max: maxVideos),
          const SizedBox(height: 20),

          const Text(
            'Anuncios disponibles',
            style: TextStyle(
              color: AppColors.textoPrimario,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // ── Tarjeta principal de video ─────────────────────────
          _VideoRewardCard(
            watched: watched,
            max: maxVideos,
            isLoading: _isLoading,
            adLoaded: _adLoaded,
            limitReached: limitReached,
            onTap: limitReached ? null : _showAd,
            onReload: _loadAd,
          ),

          const SizedBox(height: 24),

          // ── Info ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.fondoElevado,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fondoCardBorde),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline, color: AppColors.textoSecundario, size: 16),
                  SizedBox(width: 6),
                  Text('Cómo funciona',
                      style: TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
                SizedBox(height: 8),
                _InfoRow(icon: Icons.play_circle_outline, text: 'Ve el anuncio completo para ganar monedas'),
                _InfoRow(icon: Icons.refresh, text: 'Límite de 20 anuncios por día'),
                _InfoRow(icon: Icons.monetization_on_outlined, text: '50 monedas = \$0.05 USD por anuncio'),
                _InfoRow(icon: Icons.account_balance_wallet_outlined, text: 'Acumula 1,000 monedas para cobrar \$1.00'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: progreso diario ──────────────────────────────────────
class _DailyProgressCard extends StatelessWidget {
  final int watched;
  final int max;
  const _DailyProgressCard({required this.watched, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = watched / max;
    final earned = watched * AppConstants.coinsPerVideo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB91C1C), Color(0xFFDC2626), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.colorVideos.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Videos de hoy',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ]),
              Text('$watched / $max',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.monetization_on_rounded,
                color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text('$earned monedas ganadas hoy',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

// ── Widget: tarjeta de ver video ─────────────────────────────────
class _VideoRewardCard extends StatelessWidget {
  final int watched;
  final int max;
  final bool isLoading;
  final bool adLoaded;
  final bool limitReached;
  final VoidCallback? onTap;
  final VoidCallback onReload;

  const _VideoRewardCard({
    required this.watched,
    required this.max,
    required this.isLoading,
    required this.adLoaded,
    required this.limitReached,
    required this.onTap,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Column(
        children: [
          // Ícono
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: limitReached
                  ? AppColors.fondoCardBorde
                  : AppColors.colorVideos.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              limitReached
                  ? Icons.check_circle_outline_rounded
                  : Icons.play_circle_fill_rounded,
              size: 38,
              color: limitReached
                  ? AppColors.textoDeshabilitado
                  : AppColors.colorVideos,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            limitReached ? '¡Límite diario alcanzado!' : 'Ver anuncio',
            style: TextStyle(
              color: limitReached
                  ? AppColors.textoSecundario
                  : AppColors.textoPrimario,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            limitReached
                ? 'Vuelve mañana para más anuncios'
                : '${AppConstants.coinsPerVideo} monedas por anuncio completo',
            style: const TextStyle(
                color: AppColors.textoSecundario, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          if (!limitReached) ...[
            if (isLoading)
              const SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                    color: AppColors.colorVideos, strokeWidth: 2.5),
              )
            else if (!adLoaded)
              Column(children: [
                const Text('No hay anuncios disponibles ahora',
                    style: TextStyle(
                        color: AppColors.textoSecundario, fontSize: 12)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onReload,
                  child: const Text('Reintentar',
                      style: TextStyle(color: AppColors.colorVideos)),
                ),
              ])
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Ver anuncio ahora',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.colorVideos,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.textoSecundario, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 12)),
            ),
          ],
        ),
      );
}
