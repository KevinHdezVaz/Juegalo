import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/notification_service.dart';

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
  final String referralCode;
  final int referralsCount;
  final int referralEarnings;
  final bool reviewClaimed;
  final bool dailyBonusClaimed;

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
    this.referralCode      = '',
    this.referralsCount    = 0,
    this.referralEarnings  = 0,
    this.reviewClaimed     = false,
    this.dailyBonusClaimed = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final claimedAt = j['daily_bonus_claimed_at'] as String?;
    return AppUser(
      id:                 j['id'] as String,
      username:           j['username'] as String? ?? '',
      email:              j['email'] as String? ?? '',
      countryCode:        j['country_code'] as String? ?? 'MX',
      coins:              j['coins'] as int? ?? 0,
      totalEarned:        j['total_earned'] as int? ?? 0,
      dailyCoins:         j['daily_coins'] as int? ?? 0,
      dailyGoal:          j['daily_goal'] as int? ?? 1500,
      streakDays:         j['streak_days'] as int? ?? 0,
      referralCode:       j['referral_code'] as String? ?? '',
      referralsCount:     j['referrals_count'] as int? ?? 0,
      referralEarnings:   j['referral_earnings'] as int? ?? 0,
      reviewClaimed:      j['review_claimed_at'] != null,
      dailyBonusClaimed:  claimedAt != null && claimedAt.startsWith(today),
    );
  }

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

// ── Usuario actual (fetch simple, sin realtime) ───────────────────
// Se refresca cuando cambia el auth state (login/logout/token renovado).
final userProvider = StreamProvider<AppUser?>((ref) async* {
  ref.watch(authStateProvider);

  final userId = _db.auth.currentUser?.id;
  if (userId == null) { yield null; return; }

  final row = await _db
      .from('users')
      .select()
      .eq('id', userId)
      .maybeSingle();

  yield row == null ? null : AppUser.fromJson(row);
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
  Future<void> signInWithGoogle({String? referralCode}) async {
    final googleSignIn = GoogleSignIn(serverClientId: _webClientId);

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

    await _applyReferral(referralCode);
    await NotificationService.instance.requestAndSaveToken();
  }

  // Sign in anónimo (jugar sin cuenta)
  Future<void> signInAnonymously({String? referralCode}) async {
    await _db.auth.signInAnonymously();
    await _applyReferral(referralCode);
    await NotificationService.instance.requestAndSaveToken();
  }

  // Aplica código de referido si es la primera vez del usuario
  Future<void> _applyReferral(String? code) async {
    if (code == null || code.isEmpty) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _db.rpc('apply_referral_code', params: {
        'p_user_id': uid,
        'p_code'   : code,
      });
    } catch (_) {
      // No bloquear el login si el código falla
    }
  }

  // Sign out
  Future<void> signOut() async {
    await NotificationService.instance.clearToken();
    await _db.auth.signOut();
    state = const AsyncData(null);
  }
}

final userNotifierProvider =
    AsyncNotifierProvider<UserNotifier, AppUser?>(UserNotifier.new);
