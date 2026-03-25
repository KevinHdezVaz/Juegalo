import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Web OAuth client ID (para que Supabase verifique el token)
const _webClientId =
    '592011118-o2k13ab9ai4tnbt9tnl1l7dehfou7f4g.apps.googleusercontent.com';

SupabaseClient get _db => Supabase.instance.client;

// ── Modelo de usuario ─────────────────────────────────────────────
class AppUser {
  final String id;
  final String username;
  final String email;
  final String countryCode;
  final int coins;
  final int totalEarned;
  final int dailyCoins;
  final int dailyGoal;
  final int streakDays;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.countryCode,
    required this.coins,
    required this.totalEarned,
    required this.dailyCoins,
    required this.dailyGoal,
    required this.streakDays,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id:           j['id'] as String,
    username:     j['username'] as String? ?? '',
    email:        j['email'] as String? ?? '',
    countryCode:  j['country_code'] as String? ?? 'MX',
    coins:        j['coins'] as int? ?? 0,
    totalEarned:  j['total_earned'] as int? ?? 0,
    dailyCoins:   j['daily_coins'] as int? ?? 0,
    dailyGoal:    j['daily_goal'] as int? ?? 1500,
    streakDays:   j['streak_days'] as int? ?? 0,
  );

  double get balanceUsd => coins / 1000.0;
  double get dailyProgressPct => (dailyCoins / dailyGoal).clamp(0.0, 1.0);
  bool   get dailyGoalReached => dailyCoins >= dailyGoal;
}

// ── Auth state ────────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return _db.auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  return _db.auth.currentSession;
});

// ── Usuario actual con realtime ───────────────────────────────────
final userProvider = StreamProvider<AppUser?>((ref) {
  final userId = _db.auth.currentUser?.id;
  if (userId == null) return Stream.value(null);

  return _db
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((rows) => rows.isEmpty ? null : AppUser.fromJson(rows.first));
});

// ── Notifier para acciones del usuario ───────────────────────────
class UserNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _db.from('users').select().eq('id', userId).maybeSingle();
    return row == null ? null : AppUser.fromJson(row);
  }

  // Sign in con Google — nativo (sin abrir browser)
  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(serverClientId: _webClientId);

    // Abre el sheet nativo de selección de cuenta
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Sign-in cancelado');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('No se pudo obtener el ID token');

    await _db.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  // Sign in anónimo (jugar sin cuenta)
  Future<void> signInAnonymously() async {
    await _db.auth.signInAnonymously();
  }

  // Sign out
  Future<void> signOut() async {
    await _db.auth.signOut();
    state = const AsyncData(null);
  }
}

final userNotifierProvider =
    AsyncNotifierProvider<UserNotifier, AppUser?>(UserNotifier.new);
