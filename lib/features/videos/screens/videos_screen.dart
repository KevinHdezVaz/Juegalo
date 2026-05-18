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
import '../../../shared/providers/feature_flags_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/widgets/feature_disabled_screen.dart';

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

// SharedPreferences keys
const _kVideosKey    = 'videos_watched_today';
const _kResetAtKey   = 'videos_reset_at'; // unix ms: cuando vence la ventana 24 h

final videosWatchedProvider = StateProvider<int>((ref) => 0);

// ── Estado de cada slot ──────────────────────────────────────────
class _SlotState {
  RewardedAd? ad;
  bool loading     = false;
  bool loaded      = false;
  bool unavailable = false;
  bool showing     = false;
  int  retries     = 0;
  Timer? retryTimer;
}

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  late final List<_SlotState> _slots;

  // ── Cooldown entre videos (25 s) ─────────────────────────────────
  static const _kCooldownSecs = 60;
  int    _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  // ── Lock global: bloquea todos los slots mientras un video está en pantalla
  bool _globalLock = false;

  // ── Countdown 24 h ───────────────────────────────────────────────
  int    _secondsUntilReset = 0;
  Timer? _resetTimer;

  static const int _dailyLimit = AppConstants.coinsPerVideoMax; // 50

  @override
  void initState() {
    super.initState();
    _slots = List.generate(_adUnits.length, (_) => _SlotState());
    _init();
  }

  // ── Inicialización: carga contador y ventana de 24 h ────────────
  Future<void> _init() async {
    final p   = await SharedPreferences.getInstance();
    if (!mounted) return;

    final resetAt = p.getInt(_kResetAtKey) ?? 0;
    final now     = DateTime.now().millisecondsSinceEpoch;

    if (now >= resetAt) {
      // La ventana de 24 h ya expiró → resetear
      await p.setInt(_kVideosKey, 0);
      await p.remove(_kResetAtKey);
      if (!mounted) return;
      ref.read(videosWatchedProvider.notifier).state = 0;
      setState(() => _secondsUntilReset = 0);
    } else {
      final count = p.getInt(_kVideosKey) ?? 0;
      if (!mounted) return;
      ref.read(videosWatchedProvider.notifier).state = count;
      final secs = ((resetAt - now) / 1000).ceil();
      setState(() => _secondsUntilReset = secs);
      if (count >= _dailyLimit && secs > 0) _startResetCountdown();
    }

    // Cargar todos los slots de anuncios
    for (int i = 0; i < _slots.length; i++) {
      _loadAd(i);
    }
  }

  // ── Countdown hasta que se libera el límite ──────────────────────
  void _startResetCountdown() {
    _resetTimer?.cancel();
    _resetTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _resetTimer?.cancel(); return; }
      setState(() {
        if (_secondsUntilReset > 0) {
          _secondsUntilReset--;
        } else {
          _resetTimer?.cancel();
          _init(); // ventana expiró → recargar
        }
      });
    });
  }

  // ── Carga de anuncio con reintento automático ────────────────────
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 4);

  void _loadAd(int index, {bool isRetry = false}) {
    final slot = _slots[index];
    slot.retryTimer?.cancel();

    if (!isRetry) {
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
      request: const AdRequest(extras: {}),
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
            setState(() => slot.loading = false);
            slot.retryTimer = Timer(_retryDelay, () {
              if (mounted) _loadAd(index, isRetry: true);
            });
          } else {
            setState(() {
              slot.loading     = false;
              slot.loaded      = false;
              slot.unavailable = true;
            });
            slot.retryTimer = Timer(const Duration(minutes: 2), () {
              if (mounted) _loadAd(index);
            });
          }
        },
      ),
    );
  }

  // ── Cooldown entre videos ────────────────────────────────────────
  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _kCooldownSecs);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _cooldownSeconds = 0;
          t.cancel();
        }
      });
    });
  }

  // ── Mostrar anuncio ──────────────────────────────────────────────
  Future<void> _showAd(int index) async {
    final slot = _slots[index];

    // Bloquear si: global lock activo, cooldown, ya mostrando, sin anuncio
    if (_globalLock || _cooldownSeconds > 0 || slot.showing || slot.ad == null) return;

    final ad = slot.ad!;

    setState(() {
      _globalLock   = true; // bloquear todos los slots
      slot.showing  = true;
    });

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissed) {
        dismissed.dispose();
        if (mounted) {
          setState(() {
            _globalLock           = false; // liberar lock global
            _slots[index].ad      = null;
            _slots[index].showing = false;
          });
        }
        _loadAd(index);
      },
      onAdFailedToShowFullScreenContent: (failed, _) {
        failed.dispose();
        if (mounted) {
          setState(() {
            _globalLock           = false;
            _slots[index].ad      = null;
            _slots[index].showing = false;
          });
        }
        _loadAd(index);
      },
    );

    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    await ad.setServerSideOptions(
      ServerSideVerificationOptions(customData: uid),
    );

    if (!mounted) {
      _globalLock          = false;
      _slots[index].showing = false;
      return;
    }

    await ad.show(
      onUserEarnedReward: (_, __) => _creditCoins(index),
    );
  }

  // ── Registrar intento de video en servidor (fire & forget) ───────
  Future<void> _logVideoAttempt() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.rpc('log_video_attempt', params: {
        'p_user_id'  : uid,
        'p_client_ts': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[VideosScreen] log_video_attempt error: $e');
    }
  }

  // ── Acreditar monedas + actualizar contador 24 h ─────────────────
  Future<void> _creditCoins(int index) async {
    final p     = await SharedPreferences.getInstance();
    final count = (p.getInt(_kVideosKey) ?? 0) + 1;
    await p.setInt(_kVideosKey, count);

    // Registrar intento pendiente en el servidor (para auditoría SSV)
    unawaited(_logVideoAttempt());

    // Si es el primer video de la nueva ventana, fijar el resetAt (+24 h)
    final existingResetAt = p.getInt(_kResetAtKey) ?? 0;
    if (existingResetAt == 0 || DateTime.now().millisecondsSinceEpoch >= existingResetAt) {
      final newResetAt = DateTime.now().millisecondsSinceEpoch + 24 * 3600 * 1000;
      await p.setInt(_kResetAtKey, newResetAt);
      if (mounted) {
        setState(() => _secondsUntilReset = 24 * 3600);
      }
    }

    if (!mounted) return;
    ref.read(videosWatchedProvider.notifier).state = count;

    // Si alcanzó el límite, iniciar countdown 24 h
    if (count >= _dailyLimit) {
      final resetAt = p.getInt(_kResetAtKey) ?? 0;
      final secs    = ((resetAt - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (mounted) setState(() => _secondsUntilReset = secs.clamp(0, 24 * 3600));
      _startResetCountdown();
    }

    // Cooldown de 25 s entre videos
    _startCooldown();

    // Esperar 3 s para que el SSV de AdMob llegue al servidor
    await Future.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;

    ref.invalidate(userProvider);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        // ignore: use_build_context_synchronously
        context.l10n.videosCoinsEarned(AppConstants.coinsPerVideo),
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

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _resetTimer?.cancel();
    for (final s in _slots) {
      s.ad?.dispose();
      s.retryTimer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    if (flags != null && !flags.videosEnabled) {
      return FeatureDisabledScreen(
        title: context.l10n.videosMaintenance,
        subtitle:
            'Los videos con recompensa están en pausa.\nVuelve en unas horas.',
        icon: Icons.play_circle_rounded,
        theme: FeatureTheme.videos,
      );
    }

    final watched      = ref.watch(videosWatchedProvider);
    final limitReached = watched >= _dailyLimit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progreso diario ──────────────────────────────────
          _DailyProgressCard(
            watched:          watched,
            max:              _dailyLimit,
            secondsUntilReset: _secondsUntilReset,
          ),
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
              index:          i,
              slot:           _slots[i],
              limitReached:   limitReached,
              cooldownSeconds: _cooldownSeconds,
              globalLock:     _globalLock,
              onTap:          () => _showAd(i),
              onReload:       () => _loadAd(i),
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
                const Icon(Icons.schedule_rounded,
                    color: Colors.amber, size: 16),
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
                    icon: Icons.refresh, text: context.l10n.videosInfoLimit),
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
  final int       index;
  final _SlotState slot;
  final bool      limitReached;
  final int       cooldownSeconds;
  final bool      globalLock;
  final VoidCallback onTap;
  final VoidCallback onReload;

  const _VideoSlotCard({
    required this.index,
    required this.slot,
    required this.limitReached,
    required this.cooldownSeconds,
    required this.globalLock,
    required this.onTap,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = limitReached;
    // El slot está listo si: cargado, sin límite, sin cooldown y sin lock global
    final isReady = slot.loaded && !isDisabled && cooldownSeconds == 0 && !globalLock;

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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.fondoCardBorde
                      : AppColors.colorVideos.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isDisabled
                      ? Icons.block_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 30,
                  color: isDisabled
                      ? Colors.redAccent
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
            // Límite alcanzado — bloqueo 24 h
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded,
                      color: Colors.redAccent, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.videosLimitReached,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (globalLock)
            // Otro video en reproducción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Center(
                child: Icon(Icons.lock_outline_rounded,
                    size: 16, color: Colors.white24),
              ),
            )
          else if (slot.loading || slot.showing)
            const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: AppColors.colorVideos, strokeWidth: 2),
            )
          else if (slot.unavailable)
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
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: AppColors.textoSecundario, strokeWidth: 1.5),
            )
          else if (cooldownSeconds > 0)
            // Cooldown activo entre videos
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_rounded,
                      color: Colors.amber, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${cooldownSeconds}s',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Progreso diario ──────────────────────────────────────────────
class _DailyProgressCard extends StatelessWidget {
  final int watched;
  final int max;
  final int secondsUntilReset;

  const _DailyProgressCard({
    required this.watched,
    required this.max,
    required this.secondsUntilReset,
  });

  String _fmtCountdown(int s) {
    if (s <= 0) return '00:00:00';
    final h   = (s ~/ 3600).toString().padLeft(2, '0');
    final m   = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final pct          = (watched / max).clamp(0.0, 1.0);
    final earned       = watched * AppConstants.coinsPerVideo;
    final limitReached = watched >= max;

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
                Icon(
                  limitReached
                      ? Icons.block_rounded
                      : Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  limitReached
                      ? context.l10n.videosLimitReached
                      : context.l10n.videosTodayTitle,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ]),
              Text('$watched / $max',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
          if (limitReached && secondsUntilReset > 0) ...[
            // ── Countdown 24 h hasta liberar slots ─────────────
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_clock_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.videosUnlocksIn,
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _fmtCountdown(secondsUntilReset),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Icon(Icons.hourglass_top_rounded,
                          color: Colors.white54, size: 14),
                      SizedBox(height: 2),
                      Text(
                        'ventana 24 h',
                        style: TextStyle(color: Colors.white38, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (!limitReached) ...[
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
  final String   text;
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
