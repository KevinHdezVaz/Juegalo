import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/user_provider.dart';

// Monedas por nivel de racha
int _coinsForStreak(int streak) {
  if (streak >= 30) return 1000;
  if (streak >= 14) return 700;
  if (streak >= 7)  return 500;
  if (streak >= 3)  return 250;
  return 100;
}

// Próximo hito de racha
int _nextMilestone(int streak) {
  if (streak < 3)  return 3;
  if (streak < 7)  return 7;
  if (streak < 14) return 14;
  if (streak < 30) return 30;
  return streak + 1;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final claimed     = user.dailyBonusClaimed;
        final streak      = user.streakDays;
        final nextStreak  = streak + 1;
        final todayCoins  = _coinsForStreak(claimed ? streak : nextStreak);
        final nextMile    = _nextMilestone(claimed ? streak : nextStreak);
        final mileCoins   = _coinsForStreak(nextMile);

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.azulPrimario,
                      AppColors.azulPrimario.withValues(alpha: 0.80),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
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
                          const Text(
                            'Bono diario',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            streak == 0 ? 'Comienza tu racha hoy'
                                : '$streak ${streak == 1 ? "día" : "días"} seguidos',
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            '$streak días',
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
                            claimed ? 'Reclamado hoy' : 'Premio de hoy',
                            style: TextStyle(
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
                              '+$todayCoins monedas',
                              style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            'Día $nextMile → +$mileCoins monedas',
                            style: TextStyle(
                              color: AppColors.azulPrimario.withValues(alpha: 0.70),
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
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.verdePrimario.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.verdePrimario.withValues(alpha: 0.30)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.verdePrimario, size: 22),
                            const SizedBox(height: 2),
                            const Text(
                              'Reclamado',
                              style: TextStyle(
                                color: AppColors.verdePrimario,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.azulPrimario.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.azulPrimario.withValues(alpha: 0.40)),
                          ),
                          child: const Icon(Icons.play_circle_outline_rounded,
                              color: AppColors.azulPrimario, size: 22),
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
                    final dayNum   = i + 1;
                    final isActive = dayNum <= streak;
                    final isToday  = dayNum == streak + 1 && !claimed ||
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
  final int  day;
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
          width: 32, height: 32,
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
          _dayLabel(day),
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

  String _dayLabel(int d) {
    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return labels[(d - 1) % 7];
  }
}
