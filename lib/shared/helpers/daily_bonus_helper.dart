import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/number_format_ext.dart';
import '../providers/user_provider.dart';

// ── Locks de módulo (evitan llamadas concurrentes en la misma sesión) ──
bool _claimingBonus     = false;
bool _claimingGoalBonus = false;

// ─────────────────────────────────────────────────────────────────────────────
/// Llama a esto después de cualquier actividad (video, encuesta, juego).
/// Si el bono del día no fue reclamado aún, lo reclama automáticamente
/// y muestra una notificación.
///
/// La fuente de verdad es el servidor (Supabase), no SharedPreferences.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> tryClaimDailyBonus(BuildContext context, WidgetRef ref) async {
  // Lock de módulo: evita dos llamadas concurrentes en la misma sesión
  if (_claimingBonus) return;

  // Verificar desde el servidor — fuente de verdad
  final user = ref.read(userProvider).valueOrNull;
  if (user == null || user.dailyBonusClaimed) return;

  _claimingBonus = true;
  try {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final result = await Supabase.instance.client
        .rpc('claim_daily_bonus', params: {'p_user_id': uid});

    final success = result['success'] as bool? ?? false;
    if (!success) return;

    final coins  = result['coins']  as int? ?? 0;
    final streak = result['streak'] as int? ?? 1;

    ref.invalidate(userProvider);

    if (context.mounted) {
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
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    context.l10n.dailyBonusCoinsAndStreak(coins, streak, streakLabel),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          backgroundColor: AppColors.azulPrimario,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ tryClaimDailyBonus error: $e');
  } finally {
    _claimingBonus = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Llama a esto después de cualquier actividad.
/// Si el usuario acaba de alcanzar su meta diaria, otorga el bono de meta
/// y notifica. La fuente de verdad es el servidor.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> tryClaimDailyGoalBonus(BuildContext context, WidgetRef ref) async {
  if (_claimingGoalBonus) return;

  // Verificar desde el servidor — fuente de verdad
  final user = ref.read(userProvider).valueOrNull;
  if (user == null || user.dailyGoalBonusClaimed) return;

  _claimingGoalBonus = true;
  try {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final result = await Supabase.instance.client
        .rpc('claim_daily_goal_bonus', params: {'p_user_id': uid});

    final success = result['success'] as bool? ?? false;
    if (!success) return;

    final coins = result['coins'] as int? ?? 1500;

    ref.invalidate(userProvider);
    ref.invalidate(userNotifierProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Text('🎯', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.dailyGoalReachedToast,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text(context.l10n.dailyGoalBonusCoins(coins.formatted),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
                ],
              ),
            ),
          ]),
          backgroundColor: AppColors.verdePrimario,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ tryClaimDailyGoalBonus error: $e');
  } finally {
    _claimingGoalBonus = false;
  }
}
