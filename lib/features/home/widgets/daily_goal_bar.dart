import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/user_provider.dart';

class DailyGoalBar extends StatelessWidget {
  final AppUser user;
  const DailyGoalBar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final pct     = user.dailyProgressPct;
    final reached = user.dailyGoalReached;
    final remaining = (user.dailyGoal - user.dailyCoins).clamp(0, user.dailyGoal);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(reached ? '🎯' : '🔥',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    reached ? '¡Meta alcanzada! Bono x2 activo' : 'Meta de hoy',
                    style: TextStyle(
                      color: reached
                          ? AppColors.verdePrimario
                          : AppColors.textoPrimario,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${user.dailyCoins} / ${user.dailyGoal}',
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: pct,
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.fondoCardBorde,
            progressColor: reached ? AppColors.dorado : AppColors.verdePrimario,
            barRadius: const Radius.circular(4),
          ),
          if (!reached) ...[
            const SizedBox(height: 6),
            Text(
              'Faltan $remaining monedas para el bono x2',
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
