import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Solicitudes de retiro del usuario actual.
/// Incluye: pending, processing, y las pagadas en los últimos 60 días.
final cashoutRequestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];

  final since = DateTime.now()
      .subtract(const Duration(days: 60))
      .toUtc()
      .toIso8601String();

  // Activas (pending / processing)
  final active = await Supabase.instance.client
      .from('cashout_requests')
      .select()
      .eq('user_id', uid)
      .inFilter('status', ['pending', 'processing'])
      .order('created_at', ascending: false);

  // Pagadas / rechazadas en los últimos 60 días
  final recent = await Supabase.instance.client
      .from('cashout_requests')
      .select()
      .eq('user_id', uid)
      .inFilter('status', ['paid', 'rejected'])
      .gte('created_at', since)
      .order('created_at', ascending: false)
      .limit(20);

  final all = [
    ...List<Map<String, dynamic>>.from(active),
    ...List<Map<String, dynamic>>.from(recent),
  ];
  return all;
});
