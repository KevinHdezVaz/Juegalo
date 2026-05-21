import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/providers/user_provider.dart';

class DailyGoalBar extends StatelessWidget {
  final AppUser user;
  const DailyGoalBar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Bono único: una vez reclamado, no mostrar la barra
    if (user.dailyGoalBonusClaimed) return const SizedBox.shrink();

    final pct = user.dailyProgressPct;
    final reached = user.dailyGoalReached;
    final remaining =
        (user.dailyGoal - user.dailyCoins).clamp(0, user.dailyGoal);

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
              Expanded(
                child: Row(
                children: [
                  Icon(
                    reached
                        ? Icons.gps_fixed_rounded
                        : Icons.local_fire_department_rounded,
                    size: 16,
                    color: reached ? AppColors.verdePrimario : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Flexible(child: Text(
                    reached ? context.l10n.dailyGoalReached : context.l10n.dailyGoalLabel,
                    style: TextStyle(
                      color: reached
                          ? AppColors.verdePrimario
                          : AppColors.azulPrimario,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              )),
              Text(
                '${user.dailyCoins.formatted} / ${user.dailyGoal.formatted}',
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
            progressColor: reached ? AppColors.dorado : AppColors.azulPrimario,
            barRadius: const Radius.circular(4),
          ),
          if (!reached) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.dailyGoalRemaining(remaining.formatted),
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
