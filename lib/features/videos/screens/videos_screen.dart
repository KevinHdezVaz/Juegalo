import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/helpers/daily_bonus_helper.dart';

// ── Ad Unit IDs reales ───────────────────────────────────────────
const _realAdUnits = [
  'ca-app-pub-5486388630970825/4840288002',
  'ca-app-pub-5486388630970825/1584508626',
  'ca-app-pub-5486388630970825/1959913141',
  'ca-app-pub-5486388630970825/4277615994',
];

// ── Ad Unit ID de prueba (Google test ID) ────────────────────────
const _testAdUnit = 'ca-app-pub-3940256099942544/5224354917';

const _kVideosKey     = 'videos_watched_today';
const _kVideosDateKey = 'videos_watched_date';
const _kTestModeKey   = 'admob_test_mode';

final videosWatchedProvider = StateProvider<int>((ref) => 0);

// ── Estado de cada slot ──────────────────────────────────────────
class _SlotState {
  RewardedAd? ad;
  bool loading = false;
  bool loaded  = false;
}

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  late final List<_SlotState> _slots;
  bool _testMode = true; // por defecto: anuncios de prueba

  @override
  void initState() {
    super.initState();
    _slots = List.generate(_realAdUnits.length, (_) => _SlotState());
    _init();
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();

    // Cargar preferencia test/real
    final savedTestMode = p.getBool(_kTestModeKey) ?? true;
    setState(() => _testMode = savedTestMode);

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

  String _adUnitFor(int index) =>
      _testMode ? _testAdUnit : _realAdUnits[index];

  void _loadAd(int index) {
    setState(() {
      _slots[index].loading = true;
      _slots[index].loaded  = false;
    });

    RewardedAd.load(
      adUnitId: _adUnitFor(index),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _slots[index].ad      = ad;
            _slots[index].loading = false;
            _slots[index].loaded  = true;
          });
        },
        onAdFailedToLoad: (_) {
          if (!mounted) return;
          setState(() {
            _slots[index].loading = false;
            _slots[index].loaded  = false;
          });
        },
      ),
    );
  }

  Future<void> _toggleTestMode(bool value) async {
    // Descartar anuncios actuales
    for (final s in _slots) {
      s.ad?.dispose();
      s.ad      = null;
      s.loading = false;
      s.loaded  = false;
    }
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kTestModeKey, value);
    setState(() => _testMode = value);
    // Recargar con nuevo modo
    for (int i = 0; i < _slots.length; i++) {
      _loadAd(i);
    }
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
            '+${AppConstants.coinsPerVideo} monedas ganadas',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.verdePrimario,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
        await tryClaimDailyBonus(context, ref);
      }
    } catch (e) {
      debugPrint('❌ credit_coins error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al acreditar monedas: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.ad?.dispose();
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

          // ── Switch prueba/real ───────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _testMode
                  ? AppColors.azulPrimario.withValues(alpha: 0.1)
                  : AppColors.verdePrimario.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _testMode
                    ? AppColors.azulPrimario.withValues(alpha: 0.3)
                    : AppColors.verdePrimario.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _testMode
                      ? Icons.science_rounded
                      : Icons.check_circle_rounded,
                  size: 18,
                  color: _testMode
                      ? AppColors.azulPrimario
                      : AppColors.verdePrimario,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _testMode ? 'Modo prueba' : 'Anuncios reales',
                        style: TextStyle(
                          color: _testMode
                              ? AppColors.azulPrimario
                              : AppColors.verdePrimario,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _testMode
                            ? 'Los anuncios son de prueba (no generan ingresos)'
                            : 'Mostrando anuncios reales de AdMob',
                        style: const TextStyle(
                            color: AppColors.textoSecundario, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !_testMode,
                  onChanged: (v) => _toggleTestMode(!v),
                  activeColor: AppColors.verdePrimario,
                  inactiveThumbColor: AppColors.azulPrimario,
                  inactiveTrackColor:
                      AppColors.azulPrimario.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Videos disponibles',
            style: TextStyle(
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

          const SizedBox(height: 20),

          // ── Info ─────────────────────────────────────────────
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
                  Icon(Icons.info_outline,
                      color: AppColors.textoSecundario, size: 16),
                  SizedBox(width: 6),
                  Text('Cómo funciona',
                      style: TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
                SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.play_circle_outline,
                    text: 'Ve el anuncio completo para ganar monedas'),
                _InfoRow(
                    icon: Icons.refresh,
                    text: 'Límite de 20 anuncios por día'),
                _InfoRow(
                    icon: Icons.monetization_on_outlined,
                    text: '50 monedas = \$0.05 USD por anuncio'),
                _InfoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    text: 'Acumula 1,000 monedas para cobrar \$1.00'),
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
                'Video ${index + 1}',
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
            const Text('Límite alcanzado',
                style: TextStyle(
                    color: AppColors.textoDeshabilitado, fontSize: 10),
                textAlign: TextAlign.center)
          else if (slot.loading)
            const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: AppColors.colorVideos, strokeWidth: 2),
            )
          else if (!slot.loaded)
            GestureDetector(
              onTap: onReload,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded,
                      color: AppColors.textoSecundario, size: 14),
                  SizedBox(width: 4),
                  Text('Reintentar',
                      style: TextStyle(
                          color: AppColors.textoSecundario, fontSize: 11)),
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
                child: const Text('Ver',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
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
  const _DailyProgressCard({required this.watched, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct    = (watched / max).clamp(0.0, 1.0);
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
