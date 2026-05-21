import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/providers/user_provider.dart';


// Monedas exactas que paga claim_daily_bonus según el día de racha
int _coinsForStreak(int streak) {
  // Mes 1: hitos semanales escalados
  if (streak == 7) return 200;
  if (streak == 14) return 300;
  if (streak == 21) return 400;
  if (streak == 30) return 500;
  // Después del día 30: cada 7 días da 200, resto 100
  if (streak > 30 && streak % 7 == 0) return 200;
  return 100;
}

// Próximo hito donde hay bono extra
int _nextMilestone(int streak) {
  if (streak < 7) return 7;
  if (streak < 14) return 14;
  if (streak < 21) return 21;
  if (streak < 30) return 30;
  // Después del día 30: siguiente múltiplo de 7
  return ((streak ~/ 7) + 1) * 7;
}

class DailyBonusCard extends ConsumerStatefulWidget {
  const DailyBonusCard({super.key});

  @override
  ConsumerState<DailyBonusCard> createState() => _DailyBonusCardState();
}

class _DailyBonusCardState extends ConsumerState<DailyBonusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;
  bool _claiming = false;
  bool _justClaimed = false;
  int _secondsUntilReset = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Segundos hasta medianoche UTC ────────────────────────────────
  int _calcSecondsUntilMidnight() {
    final now = DateTime.now().toUtc();
    final midnight = DateTime.utc(now.year, now.month, now.day + 1);
    return midnight.difference(now).inSeconds;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsUntilReset = _calcSecondsUntilMidnight());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }
      setState(() {
        _secondsUntilReset = _calcSecondsUntilMidnight();
      });
    });
  }

  String _fmtCountdown(int s) {
    if (s <= 0) return '00:00:00';
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  Future<void> _claimBonus() async {
    if (_claiming || _justClaimed) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    // ── Verificar actividad del día (video o encuesta) ───────────────
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final videosHoy = prefs.getInt('videos_watched_today') ?? 0;
    bool tieneActividad = videosHoy > 0;

    if (!tieneActividad) {
      // Sin videos locales → revisar encuestas en Supabase
      final surveys = await Supabase.instance.client
          .from('transactions')
          .select('id')
          .eq('user_id', uid)
          .eq('source', 'cpx_research')
          .gte('created_at', '${today}T00:00:00.000Z')
          .limit(1);
      tieneActividad = (surveys as List).isNotEmpty;
    }

    if (!tieneActividad) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Text('🎯', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.dailyBonusNoActivity,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ]),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ));
      }
      return;
    }

    setState(() => _claiming = true);
    try {
      final result = await Supabase.instance.client
          .rpc('claim_daily_bonus', params: {'p_user_id': uid});

      final success = result['success'] as bool? ?? false;
      ref.invalidate(userProvider);

      if (!mounted) return;
      if (success) {
        setState(() => _justClaimed = true);
        _startCountdown();
        final coins = result['coins'] as int? ?? 0;
        final streak = result['streak'] as int? ?? 1;
        final streakLabel = streak == 1
            ? context.l10n.dailyBonusStreakLabelOne
            : context.l10n.dailyBonusStreakLabelMany;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.dailyBonusClaimedToast,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(
                      context.l10n
                          .dailyBonusCoinsAndStreak(coins, streak, streakLabel),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ]),
            backgroundColor: AppColors.azulPrimario,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        final reason = result['reason'] as String? ?? '';
        final msg = reason == 'no_activity'
            ? context.l10n.dailyBonusNoActivity
            : context.l10n.dailyBonusClaimed;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: reason == 'no_activity' ? Colors.orange : null,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      debugPrint('❌ _claimBonus error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.dailyBonusErrorClaiming),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final claimed = user.dailyBonusClaimed || _justClaimed;

        // Iniciar countdown si ya fue reclamado y el timer no está corriendo
        if (claimed && _countdownTimer == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _startCountdown());
        }
        final streak = user.streakDays;
        final nextStreak = streak + 1;
        final todayCoins = _coinsForStreak(claimed ? streak : nextStreak);
        final nextMile = _nextMilestone(claimed ? streak : nextStreak);
        final mileCoins = _coinsForStreak(nextMile);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.fondoCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fondoCardBorde),
            boxShadow: [
              BoxShadow(
                color: AppColors.azulPrimario.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.azulPrimario,
                      AppColors.azulPrimario.withValues(alpha: 0.80),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.orange, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.dailyBonusTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            streak == 0
                                ? context.l10n.dailyBonusStreakZero
                                : streak == 1
                                    ? context.l10n.dailyBonusStreakOne(streak)
                                    : context.l10n.dailyBonusStreakMany(streak),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Días actuales
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.dailyBonusDays(streak),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Cuerpo ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Premio de hoy
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            claimed
                                ? context.l10n.dailyBonusClaimed
                                : context.l10n.dailyBonusTodayPrize,
                            style: const TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: AppColors.dorado, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n
                                  .dailyBonusCoins(todayCoins.formatted),
                              style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.dailyBonusNextMilestone(
                                nextMile, mileCoins.formatted),
                            style: TextStyle(
                              color: AppColors.azulPrimario
                                  .withValues(alpha: 0.70),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Estado del bono
                    if (claimed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              AppColors.verdePrimario.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.verdePrimario
                                  .withValues(alpha: 0.30)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.verdePrimario, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.dailyBonusClaimedBadge,
                              style: const TextStyle(
                                color: AppColors.verdePrimario,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.dailyBonusAvailableIn,
                              style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _fmtCountdown(_secondsUntilReset),
                              style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _claimBonus,
                        child: ScaleTransition(
                          scale: _claiming
                              ? const AlwaysStoppedAnimation(1.0)
                              : _scale,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.azulPrimario
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.azulPrimario
                                      .withValues(alpha: 0.50)),
                            ),
                            child: _claiming
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.azulPrimario,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Icon(Icons.card_giftcard_rounded,
                                    color: AppColors.azulPrimario, size: 24),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Días de la semana ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final dayNum = i + 1;
                    final isActive = dayNum <= streak;
                    final isToday = dayNum == streak + 1 && !claimed ||
                        dayNum == streak && claimed;
                    return _DayCircle(
                      day: dayNum,
                      isActive: isActive,
                      isToday: isToday,
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayCircle extends StatelessWidget {
  final int day;
  final bool isActive;
  final bool isToday;

  const _DayCircle({
    required this.day,
    required this.isActive,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.azulPrimario
                : isToday
                    ? AppColors.azulPrimario.withValues(alpha: 0.15)
                    : AppColors.fondoElevado,
            border: isToday
                ? Border.all(color: AppColors.azulPrimario, width: 2)
                : null,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.local_fire_department_rounded,
                    color: Colors.orange, size: 16)
                : Text(
                    '$day',
                    style: TextStyle(
                      color: isToday
                          ? AppColors.azulPrimario
                          : AppColors.textoDeshabilitado,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _dayLabel(context, day),
          style: TextStyle(
            color: isActive || isToday
                ? AppColors.textoPrimario
                : AppColors.textoDeshabilitado,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _dayLabel(BuildContext context, int d) {
    final l = context.l10n;
    final labels = [
      l.dailyBonusDayMon,
      l.dailyBonusDayTue,
      l.dailyBonusDayWed,
      l.dailyBonusDayThu,
      l.dailyBonusDayFri,
      l.dailyBonusDaySat,
      l.dailyBonusDaySun,
    ];
    return labels[(d - 1) % 7];
  }
}
