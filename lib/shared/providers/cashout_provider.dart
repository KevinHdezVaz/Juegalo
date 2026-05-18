import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Solicitudes de retiro del usuario actual.
/// Incluye: pending, processing, y las pagadas/rechazadas HOY únicamente
/// (al día siguiente desaparecen del historial).
final cashoutRequestsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];

  // Traer pagadas/rechazadas de los últimos 2 días (margen suficiente)
  final since = DateTime.now()
      .subtract(const Duration(days: 2))
      .toUtc()
      .toIso8601String();

  // Activas (pending / processing) — siempre visibles
  final active = await Supabase.instance.client
      .from('cashout_requests')
      .select()
      .eq('user_id', uid)
      .inFilter('status', ['pending', 'processing'])
      .order('created_at', ascending: false);

  // Pagadas / rechazadas recientes (últimos 2 días para no traer demasiado)
  final recent = await Supabase.instance.client
      .from('cashout_requests')
      .select()
      .eq('user_id', uid)
      .inFilter('status', ['paid', 'rejected'])
      .gte('created_at', since)
      .order('created_at', ascending: false)
      .limit(20);

  // Filtrar para mostrar pagadas/rechazadas solo si fueron procesadas HOY
  final today = DateTime.now();
  final recentHoy = List<Map<String, dynamic>>.from(recent).where((r) {
    // Preferimos processed_at; si es null usamos updated_at o created_at
    final raw = r['processed_at'] ?? r['updated_at'] ?? r['created_at'];
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return false;
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }).toList();

  return [
    ...List<Map<String, dynamic>>.from(active),
    ...recentHoy,
  ];
});
