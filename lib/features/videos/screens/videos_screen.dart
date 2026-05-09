import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/helpers/daily_bonus_helper.dart';

// ── Ad Unit IDs por plataforma ───────────────────────────────────
final _adUnits = Platform.isIOS
    ? const [
        'ca-app-pub-5486388630970825/3159932254',
        'ca-app-pub-5486388630970825/9729729552',
        'ca-app-pub-5486388630970825/6037377039',
        'ca-app-pub-5486388630970825/7103566216',
      ]
    : const [
        'ca-app-pub-5486388630970825/4840288002',
        'ca-app-pub-5486388630970825/1584508626',
        'ca-app-pub-5486388630970825/1959913141',
        'ca-app-pub-5486388630970825/4277615994',
      ];

const _kVideosKey     = 'videos_watched_today';
const _kVideosDateKey = 'videos_watched_date';

final videosWatchedProvider = StateProvider<int>((ref) => 0);

// ── Estado de cada slot ──────────────────────────────────────────
class _SlotState {
  RewardedAd? ad;
  bool loading    = false;
  bool loaded     = false;
  bool unavailable = false; // sin inventario tras N reintentos
  int  retries    = 0;
  Timer? retryTimer;
}

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  late final List<_SlotState> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List.generate(_adUnits.length, (_) => _SlotState());
    _init();
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();

    // Cargar contador diario
    final date  = p.getString(_kVideosDateKey) ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (date != today) {
      await p.setInt(_kVideosKey, 0);
      await p.setString(_kVideosDateKey, today);
      ref.read(videosWatchedProvider.notifier).state = 0;
    } else {
      ref.read(videosWatchedProvider.notifier).state =
          p.getInt(_kVideosKey) ?? 0;
    }

    // Cargar todos los anuncios
    for (int i = 0; i < _slots.length; i++) {
      _loadAd(i);
    }
  }

  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 4);

  void _loadAd(int index, {bool isRetry = false}) {
    final slot = _slots[index];
    slot.retryTimer?.cancel();

    if (!isRetry) {
      // Reset completo al cargar manualmente
      setState(() {
        slot.loading     = true;
        slot.loaded      = false;
        slot.unavailable = false;
        slot.retries     = 0;
      });
    } else {
      setState(() {
        slot.loading = true;
        slot.loaded  = false;
      });
    }

    RewardedAd.load(
      adUnitId: _adUnits[index],
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            slot.ad          = ad;
            slot.loading     = false;
            slot.loaded      = true;
            slot.unavailable = false;
            slot.retries     = 0;
          });
        },
        onAdFailedToLoad: (_) {
          if (!mounted) return;
          slot.retries++;
          if (slot.retries < _maxRetries) {
            // Auto-retry silencioso con delay
            setState(() => slot.loading = false);
            slot.retryTimer = Timer(_retryDelay, () {
              if (mounted) _loadAd(index, isRetry: true);
            });
          } else {
            // Sin inventario — mostrar mensaje informativo
            setState(() {
              slot.loading     = false;
              slot.loaded      = false;
              slot.unavailable = true;
            });
            // Volver a intentar automáticamente en 2 minutos
            slot.retryTimer = Timer(const Duration(minutes: 2), () {
              if (mounted) _loadAd(index);
            });
          }
        },
      ),
    );
  }

  Future<void> _showAd(int index) async {
    final slot = _slots[index];
    if (slot.ad == null) return;

    slot.ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _slots[index].ad = null;
        _loadAd(index);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _slots[index].ad = null;
        _loadAd(index);
      },
    );

    await slot.ad!.show(
      onUserEarnedReward: (_, __) => _creditCoins(index),
    );
  }

  Future<void> _creditCoins(int index) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await Supabase.instance.client.rpc('credit_coins', params: {
        'p_user_id'    : uid,
        'p_coins'      : AppConstants.coinsPerVideo,
        'p_source'     : 'video',
        'p_description': 'Video ${index + 1} completado',
      });

      final p     = await SharedPreferences.getInstance();
      final count = (p.getInt(_kVideosKey) ?? 0) + 1;
      await p.setInt(_kVideosKey, count);
      ref.read(videosWatchedProvider.notifier).state = count;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            context.l10n.videosCoinsEarned(AppConstants.coinsPerVideo),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.verdePrimario,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
        await tryClaimDailyBonus(context, ref);
        await tryClaimDailyGoalBonus(context, ref);
      }
    } catch (e) {
      debugPrint('❌ credit_coins error: $e');
      if (mounted) {
        final isLimitError = e.toString().contains('daily_video_limit_reached');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isLimitError
                ? context.l10n.videosLimitReached
                : context.l10n.videosErrorCredit(e.toString()),
          ),
          backgroundColor: isLimitError ? Colors.orange : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.ad?.dispose();
      s.retryTimer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watched      = ref.watch(videosWatchedProvider);
    final maxVideos    = AppConstants.coinsPerVideoMax;
    final limitReached = watched >= maxVideos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progreso diario ──────────────────────────────────
          _DailyProgressCard(watched: watched, max: maxVideos),
          const SizedBox(height: 16),

          Text(
            context.l10n.videosTitle,
            style: const TextStyle(
              color: AppColors.textoPrimario,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // ── Grid 2×2 de slots ────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _slots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (_, i) => _VideoSlotCard(
              index: i,
              slot: _slots[i],
              limitReached: limitReached,
              onTap: () => _showAd(i),
              onReload: () => _loadAd(i),
            ),
          ),

          const SizedBox(height: 16),

          // ── Aviso disponibilidad de anuncios ─────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.videosAvailabilityNote,
                    style: const TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Info ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.fondoElevado,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fondoCardBorde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.textoSecundario, size: 16),
                  const SizedBox(width: 6),
                  Text(context.l10n.videosHowItWorks,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.play_circle_outline,
                    text: context.l10n.videosInfoFull),
                _InfoRow(
                    icon: Icons.refresh,
                    text: context.l10n.videosInfoLimit),
                _InfoRow(
                    icon: Icons.monetization_on_outlined,
                    text: context.l10n.videosInfoCoins),
                _InfoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    text: context.l10n.videosInfoAccumulate),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de slot ──────────────────────────────────────────────
class _VideoSlotCard extends StatelessWidget {
  final int index;
  final _SlotState slot;
  final bool limitReached;
  final VoidCallback onTap;
  final VoidCallback onReload;

  const _VideoSlotCard({
    required this.index,
    required this.slot,
    required this.limitReached,
    required this.onTap,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final isReady    = slot.loaded && !limitReached;
    final isDisabled = limitReached;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? AppColors.colorVideos.withValues(alpha: 0.5)
              : AppColors.fondoCardBorde,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ícono + info
          Column(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.fondoCardBorde
                      : AppColors.colorVideos.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isDisabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 30,
                  color: isDisabled
                      ? AppColors.textoDeshabilitado
                      : AppColors.colorVideos,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.videosSlot(index + 1),
                style: TextStyle(
                  color: isDisabled
                      ? AppColors.textoSecundario
                      : AppColors.textoPrimario,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on_rounded,
                      size: 12,
                      color: isDisabled
                          ? AppColors.textoDeshabilitado
                          : Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    '+${AppConstants.coinsPerVideo}',
                    style: TextStyle(
                      color: isDisabled
                          ? AppColors.textoDeshabilitado
                          : AppColors.textoPrimario,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Botón / estado
          if (isDisabled)
            Text(context.l10n.videosLimitReached,
                style: const TextStyle(
                    color: AppColors.textoDeshabilitado, fontSize: 10),
                textAlign: TextAlign.center)
          else if (slot.loading)
            const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: AppColors.colorVideos, strokeWidth: 2),
            )
          else if (slot.unavailable)
            // Sin inventario — mensaje claro, no parece error
            GestureDetector(
              onTap: onReload,
              child: Column(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: Colors.amber, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.videosUnavailable,
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (!slot.loaded)
            // Cargando silencioso (retry automático en curso)
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: AppColors.textoSecundario, strokeWidth: 1.5),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorVideos,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(context.l10n.videosWatch,
                    style:
                        const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Progreso diario ──────────────────────────────────────────────
class _DailyProgressCard extends StatefulWidget {
  final int watched;
  final int max;
  const _DailyProgressCard({required this.watched, required this.max});

  @override
  State<_DailyProgressCard> createState() => _DailyProgressCardState();
}

class _DailyProgressCardState extends State<_DailyProgressCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now      = DateTime.now().toUtc();
    final midnight = DateTime.utc(now.year, now.month, now.day + 1);
    setState(() => _remaining = midnight.difference(now));
  }

  String get _countdown {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watched       = widget.watched;
    final max           = widget.max;
    final pct           = (watched / max).clamp(0.0, 1.0);
    final earned        = watched * AppConstants.coinsPerVideo;
    final limitReached  = watched >= max;

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
              Row(children: [
                const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(context.l10n.videosTodayTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ]),
              Text('$watched / $max',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white30,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          if (limitReached) ...[
            // ── Countdown hasta medianoche UTC ──────────────────
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.videosResetsIn,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _countdown,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(context.l10n.videosEarnedToday(earned),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
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
