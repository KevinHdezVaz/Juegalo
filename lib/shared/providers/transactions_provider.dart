import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Últimas 5 transacciones del usuario (preview en wallet).
/// Se puede invalidar desde cualquier pantalla (ej. videos) para forzar refresco.
final transactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];
  final rows = await Supabase.instance.client
      .from('transactions')
      .select()
      .eq('user_id', uid)
      .order('created_at', ascending: false)
      .limit(5);
  return List<Map<String, dynamic>>.from(rows);
});
