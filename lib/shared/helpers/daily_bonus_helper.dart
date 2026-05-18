import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/l10n_ext.dart';
import '../../core/utils/number_format_ext.dart';
import '../providers/user_provider.dart';

// ── Claves de SharedPreferences ──────────────────────────────────
const _kBonusClaimedKey     = 'daily_bonus_claimed_date';
const _kGoalBonusClaimedKey = 'daily_goal_bonus_claimed_date';

// ── Locks de módulo (evitan llamadas concurrentes en la misma sesión) ──
bool _claimingBonus     = false;
bool _claimingGoalBonus = false;

/// Devuelve la fecha de hoy en UTC (yyyy-MM-dd) para comparar con SharedPreferences.
String get _today => DateTime.now().toUtc().toIso8601String().substring(0, 10);

// ─────────────────────────────────────────────────────────────────────────────
/// Llama a esto después de cualquier actividad (video, encuesta, juego).
/// Si el bono del día no fue reclamado aún, lo reclama automáticamente
/// y muestra una notificación.
///
/// Protecciones contra doble reclamo (3 capas):
///   1. Lock de módulo (_claimingBonus): bloquea llamadas concurrentes en sesión.
///   2. SharedPreferences: persiste que ya fue reclamado hoy entre llamadas.
///   3. RPC claim_daily_bonus: valida con SELECT ... FOR UPDATE en Supabase.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> tryClaimDailyBonus(BuildContext context, WidgetRef ref) async {
  // Capa 1 — Lock de módulo: evita dos llamadas concurrentes en la misma sesión
  if (_claimingBonus) return;

  // Capa 2a — SharedPreferences: check instantáneo sin depender del stream
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(_kBonusClaimedKey) == _today) return;

  // Capa 2b — Stream de Supabase: el servidor ya marcó hoy como reclamado
  final user = ref.read(userProvider).valueOrNull;
  if (user == null || user.dailyBonusClaimed) {
    // Sincronizar SharedPreferences si el servidor ya lo sabe
    if (user?.dailyBonusClaimed == true) {
      await prefs.setString(_kBonusClaimedKey, _today);
    }
    return;
  }

  _claimingBonus = true;
  try {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    // Capa 3 — RPC con SELECT ... FOR UPDATE en Supabase
    final result = await Supabase.instance.client
        .rpc('claim_daily_bonus', params: {'p_user_id': uid});

    final success = result['success'] as bool? ?? false;
    if (!success) {
      // El servidor rechazó: ya fue reclamado hoy (posiblemente desde otro hilo)
      await prefs.setString(_kBonusClaimedKey, _today);
      return;
    }

    // ✅ Reclamado con éxito — guardar inmediatamente en SharedPreferences
    await prefs.setString(_kBonusClaimedKey, _today);

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
/// y notifica. Mismas 3 capas de protección que tryClaimDailyBonus.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> tryClaimDailyGoalBonus(BuildContext context, WidgetRef ref) async {
  // Capa 1 — Lock de módulo
  if (_claimingGoalBonus) return;

  // Capa 2a — SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(_kGoalBonusClaimedKey) == _today) return;

  // Capa 2b — Stream de Supabase
  final user = ref.read(userProvider).valueOrNull;
  if (user == null || user.dailyGoalBonusClaimed) {
    if (user?.dailyGoalBonusClaimed == true) {
      await prefs.setString(_kGoalBonusClaimedKey, _today);
    }
    return;
  }

  _claimingGoalBonus = true;
  try {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    // Capa 3 — RPC con SELECT ... FOR UPDATE en Supabase
    final result = await Supabase.instance.client
        .rpc('claim_daily_goal_bonus', params: {'p_user_id': uid});

    final success = result['success'] as bool? ?? false;
    if (!success) {
      await prefs.setString(_kGoalBonusClaimedKey, _today);
      return;
    }

    // ✅ Reclamado — guardar inmediatamente
    await prefs.setString(_kGoalBonusClaimedKey, _today);

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
