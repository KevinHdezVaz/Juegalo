import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Solicitudes de retiro del usuario actual.
/// Incluye: pending, processing, y las pagadas en los últimos 7 días.
final cashoutRequestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];

  final since = DateTime.now()
      .subtract(const Duration(days: 1))
      .toUtc()
      .toIso8601String();

  // Activas (pending / processing)
  final active = await Supabase.instance.client
      .from('cashout_requests')
      .select()
      .eq('user_id', uid)
      .inFilter('status', ['pending', 'processing'])
      .order('created_at', ascending: false);

  // Pagadas en los últimos 7 días
  final recentPaid = await Supabase.instance.client
      .from('cashout_requests')
      .select()
      .eq('user_id', uid)
      .eq('status', 'paid')
      .gte('processed_at', since)
      .order('processed_at', ascending: false)
      .limit(3);

  final all = [
    ...List<Map<String, dynamic>>.from(active),
    ...List<Map<String, dynamic>>.from(recentPaid),
  ];
  return all;
});
