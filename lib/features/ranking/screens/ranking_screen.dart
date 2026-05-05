import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';

// ── Modelo ────────────────────────────────────────────────────────
class RankEntry {
  final int rank;
  final String id;
  final String username;
  final int weeklyCoins;
  final int streakDays;

  const RankEntry({
    required this.rank,
    required this.id,
    required this.username,
    required this.weeklyCoins,
    required this.streakDays,
  });

  factory RankEntry.fromJson(Map<String, dynamic> j, {required int rank}) =>
      RankEntry(
        rank: rank,
        id: j['id'] as String,
        username: j['username'] as String? ?? 'Jugador',
        weeklyCoins: j['weekly_coins'] as int? ?? 0,
        streakDays: j['streak_days'] as int? ?? 0,
      );

  double get usd => weeklyCoins / 10000.0;
  String get initials => username.isNotEmpty ? username[0].toUpperCase() : '?';
}

// ── Modelos adicionales ───────────────────────────────────────────
class LastWinner {
  final int rank;
  final String username;
  final int prize;

  const LastWinner({
    required this.rank,
    required this.username,
    required this.prize,
  });

  String get initials => username.isNotEmpty ? username[0].toUpperCase() : '?';
}

// ── Providers ─────────────────────────────────────────────────────
final rankingProvider =
    FutureProvider.autoDispose<List<RankEntry>>((ref) async {
  final rows = await Supabase.instance.client
      .from('users')
      .select('id, username, weekly_coins, streak_days')
      .gt('weekly_coins', 0)
      .order('weekly_coins', ascending: false)
      .limit(50);
  return List.generate(
    rows.length,
    (i) => RankEntry.fromJson(rows[i], rank: i + 1),
  );
});

final myWeeklyRankProvider =
    FutureProvider.autoDispose<({int rank, int coins})?>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;
  final me = await Supabase.instance.client
      .from('users')
      .select('weekly_coins')
      .eq('id', uid)
      .maybeSingle();
  if (me == null) return null;
  final myCoins = me['weekly_coins'] as int? ?? 0;
  final res = await Supabase.instance.client
      .from('users')
      .select('id')
      .gt('weekly_coins', myCoins)
      .count(CountOption.exact);
  return (rank: (res.count) + 1, coins: myCoins);
});

// Premio de la semana pasada del usuario actual (para celebration dialog)
final myLastPrizeProvider =
    FutureProvider.autoDispose<({int rank, int prize, String createdAt})?>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;
  final since =
      DateTime.now().subtract(const Duration(days: 8)).toIso8601String();
  final rows = await Supabase.instance.client
      .from('transactions')
      .select('coins, description, created_at')
      .eq('user_id', uid)
      .eq('source', 'ranking_prize')
      .gte('created_at', since)
      .order('created_at', ascending: false)
      .limit(1);
  if (rows.isEmpty) return null;
  final coins = rows[0]['coins'] as int? ?? 0;
  final createdAt = rows[0]['created_at'] as String? ?? '';
  // Extraer posición del description: "Premio ranking semanal #1 🏆"
  final desc = rows[0]['description'] as String? ?? '';
  final match = RegExp(r'#(\d)').firstMatch(desc);
  final rank = int.tryParse(match?.group(1) ?? '') ?? 1;
  return (rank: rank, prize: coins, createdAt: createdAt);
});

// Ganadores de la semana pasada (últimos 8 días)
final lastWeekWinnersProvider =
    FutureProvider.autoDispose<List<LastWinner>>((ref) async {
  final since =
      DateTime.now().subtract(const Duration(days: 8)).toIso8601String();
  final rows = await Supabase.instance.client
      .from('transactions')
      .select('coins, users(username)')
      .eq('source', 'ranking_prize')
      .gte('created_at', since)
      .order('coins', ascending: false)
      .limit(3);
  if (rows.isEmpty) return [];
  return rows.asMap().entries.map((e) {
    final i = e.key;
    final row = e.value;
    final user = row['users'] as Map<String, dynamic>? ?? {};
    return LastWinner(
      rank: i + 1,
      username: user['username'] as String? ?? 'Jugador',
      prize: row['coins'] as int? ?? 0,
    );
  }).toList();
});

// ── Utilidades ────────────────────────────────────────────────────
String _countdown() {
  final now = DateTime.now().toUtc();
  final days = (8 - now.weekday) % 7;
  final next =
      DateTime.utc(now.year, now.month, now.day + (days == 0 ? 7 : days));
  final diff = next.difference(now);
  final d = diff.inDays;
  final h = diff.inHours % 24;
  final m = diff.inMinutes % 60;
  if (d > 0) return '${d}d ${h}h ${m}m';
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

Color _rankBadgeColor(int rank) {
  if (rank == 1) return const Color(0xFFFFD700);
  if (rank == 2) return const Color(0xFFCBD5E1);
  if (rank == 3) return const Color(0xFFFCA16C);
  if (rank <= 10) return const Color(0xFF3B82F6);
  return AppColors.textoDeshabilitado;
}

Color _rankBadgeBg(int rank) {
  if (rank == 1) return const Color(0xFFFFF9E6);
  if (rank == 2) return const Color(0xFFF1F5F9);
  if (rank == 3) return const Color(0xFFFFF4EE);
  if (rank <= 10) return const Color(0xFFEFF6FF);
  return AppColors.fondoCard;
}

// ── Pantalla ──────────────────────────────────────────────────────
class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  static const _kPrizeDialogKey = 'ranking_prize_dialog_shown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPrize());
  }

  Future<void> _checkPrize() async {
    final prize = await ref.read(myLastPrizeProvider.future);
    if (prize == null) return;
    if (!mounted) return;

    // Solo mostrar el dialog una vez por premio (persiste entre sesiones)
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_kPrizeDialogKey);
    if (lastShown == prize.createdAt) return;

    await prefs.setString(_kPrizeDialogKey, prize.createdAt);
    if (!mounted) return;
    _showCelebrationDialog(prize.rank, prize.prize);
  }

  void _showCelebrationDialog(int rank, int prize) {
    final emojis = ['🥇', '🥈', '🥉'];
    final labels = [
      context.l10n.rankingCelebFirst,
      context.l10n.rankingCelebSecond,
      context.l10n.rankingCelebThird,
    ];
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFCBD5E1),
      const Color(0xFFFCA16C)
    ];
    final idx = (rank - 1).clamp(0, 2);
    final emoji = emojis[idx];
    final label = labels[idx];
    final color = colors[idx];

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2A6E), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: 0.50), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 24),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                context.l10n.rankingCelebSubtitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.40)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('+${prize.formatted}',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w900,
                                fontSize: 28)),
                        Text(context.l10n.rankingCelebCoinsLabel,
                            style:
                                const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(context.l10n.rankingCelebButton,
                      style:
                          const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _refresh() {
    ref.invalidate(rankingProvider);
    ref.invalidate(myWeeklyRankProvider);
    ref.invalidate(lastWeekWinnersProvider);
    ref.invalidate(myLastPrizeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final rankingAsync = ref.watch(rankingProvider);
    final myRankAsync = ref.watch(myWeeklyRankProvider);
    final lastWinnersAsync = ref.watch(lastWeekWinnersProvider);
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return rankingAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.azulPrimario)),
      error: (e, _) =>
          _ErrorView(onRetry: () => ref.invalidate(rankingProvider)),
      data: (entries) => _RankingBody(
        entries: entries,
        myId: myId,
        myRankAsync: myRankAsync,
        lastWinnersAsync: lastWinnersAsync,
        onRefresh: _refresh,
      ),
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────
class _RankingBody extends StatelessWidget {
  final List<RankEntry> entries;
  final String? myId;
  final AsyncValue<({int rank, int coins})?> myRankAsync;
  final AsyncValue<List<LastWinner>> lastWinnersAsync;
  final VoidCallback onRefresh;

  const _RankingBody({
    required this.entries,
    required this.myId,
    required this.myRankAsync,
    required this.lastWinnersAsync,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = entries.isEmpty;

    return isEmpty
        ? _EmptyState(
            myRankAsync: myRankAsync,
            lastWinnersAsync: lastWinnersAsync,
            onRefresh: onRefresh)
        : _RankList(
            entries: entries,
            myId: myId,
            myRankAsync: myRankAsync,
            lastWinnersAsync: lastWinnersAsync,
            onRefresh: onRefresh);
  }
}

// ── Dialog informativo del ranking ───────────────────────────────
void _showInfoDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2A6E), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono + título
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 14),
            Text(context.l10n.rankingInfoTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              context.l10n.rankingInfoSubtitle,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            // Premios
            _InfoPrizeRow(
              emoji: '🥇',
              label: context.l10n.rankingInfoFirst,
              desc: context.l10n.rankingInfoFirstDesc,
              coins: '2,500',
              color: const Color(0xFFFFD700),
            ),
            const SizedBox(height: 10),
            _InfoPrizeRow(
              emoji: '🥈',
              label: context.l10n.rankingInfoSecond,
              desc: context.l10n.rankingInfoSecondDesc,
              coins: '1,000',
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 10),
            _InfoPrizeRow(
              emoji: '🥉',
              label: context.l10n.rankingInfoThird,
              desc: context.l10n.rankingInfoThirdDesc,
              coins: '500',
              color: const Color(0xFFFCA16C),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.rankingInfoHowToEarn,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  _InfoTip(
                      emoji: '🎮', text: context.l10n.rankingInfoTipGames),
                  const SizedBox(height: 5),
                  _InfoTip(emoji: '📋', text: context.l10n.rankingInfoTipSurveys),
                  const SizedBox(height: 5),
                  _InfoTip(emoji: '▶️', text: context.l10n.rankingInfoTipVideos),
                  const SizedBox(height: 5),
                  _InfoTip(
                      emoji: '🔥',
                      text: context.l10n.rankingInfoTipStreak),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D4ED8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(context.l10n.rankingInfoGotIt,
                    style:
                        const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoPrizeRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String desc;
  final String coins;
  final Color color;

  const _InfoPrizeRow({
    required this.emoji,
    required this.label,
    required this.desc,
    required this.coins,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  Text(desc,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 11, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                Text(coins,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ],
            ),
          ],
        ),
      );
}

class _InfoTip extends StatelessWidget {
  final String emoji;
  final String text;
  const _InfoTip({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      );
}

// ── Header con premios + countdown ───────────────────────────────
class _HeroHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HeroHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2A6E), Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + refresh
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.rankingTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 0.3)),
                    Text(context.l10n.rankingSubtitle,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              // Countdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    Text(_countdown(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botón info
              GestureDetector(
                onTap: () => _showInfoDialog(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Premios
          Row(
            children: [
              Expanded(
                  child: _PrizeCard(
                emoji: '🥇',
                pos: context.l10n.rankingPos1,
                coins: '2,500',
                color: const Color(0xFFFFD700),
                glow: true,
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _PrizeCard(
                emoji: '🥈',
                pos: context.l10n.rankingPos2,
                coins: '1,000',
                color: const Color(0xFFCBD5E1),
                glow: false,
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: _PrizeCard(
                emoji: '🥉',
                pos: context.l10n.rankingPos3,
                coins: '500',
                color: const Color(0xFFFCA16C),
                glow: false,
              )),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.refresh_rounded,
                      color: Colors.white38, size: 11),
                  const SizedBox(width: 4),
                  Text(context.l10n.rankingResetsMonday,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
              Text(context.l10n.rankingTop50,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final String emoji;
  final String pos;
  final String coins;
  final Color color;
  final bool glow;

  const _PrizeCard({
    required this.emoji,
    required this.pos,
    required this.coins,
    required this.color,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: glow ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: glow ? color.withValues(alpha: 0.60) : Colors.white24,
            width: glow ? 1.5 : 1,
          ),
          boxShadow: glow
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.35), blurRadius: 12)
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 11),
                const SizedBox(width: 3),
                Text(coins,
                    style: TextStyle(
                        color: glow ? color : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
              ],
            ),
            Text(pos,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55), fontSize: 10)),
          ],
        ),
      );
}

// ── Estado vacío ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final AsyncValue<({int rank, int coins})?> myRankAsync;
  final AsyncValue<List<LastWinner>> lastWinnersAsync;
  final VoidCallback onRefresh;
  const _EmptyState(
      {required this.myRankAsync,
      required this.lastWinnersAsync,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.azulPrimario,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            _HeroHeader(onRefresh: onRefresh),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.fondoCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fondoCardBorde),
                    ),
                    child: Column(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(context.l10n.rankingBeFirst,
                            style: const TextStyle(
                                color: AppColors.textoPrimario,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.rankingEmptyDesc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textoSecundario,
                              fontSize: 13,
                              height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _EmptyPodiumSlot(
                                height: 60,
                                label: '#2',
                                emoji: '🥈',
                                color: const Color(0xFFF1F5F9)),
                            _EmptyPodiumSlot(
                                height: 80,
                                label: '#1',
                                emoji: '🥇',
                                color: const Color(0xFFFFF9E6)),
                            _EmptyPodiumSlot(
                                height: 44,
                                label: '#3',
                                emoji: '🥉',
                                color: const Color(0xFFFFF4EE)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  myRankAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (data) => data == null
                        ? const SizedBox.shrink()
                        : _MyPositionCard(rank: data.rank, coins: data.coins),
                  ),
                  const SizedBox(height: 16),
                  _TipRow(
                      icon: Icons.sports_esports_rounded,
                      color: AppColors.colorJuegos,
                      text: context.l10n.rankingTipGames),
                  const SizedBox(height: 8),
                  _TipRow(
                      icon: Icons.assignment_outlined,
                      color: AppColors.colorEncuestas,
                      text: context.l10n.rankingSurveysTip),
                  _TipRow(
                      icon: Icons.play_circle_outline_rounded,
                      color: AppColors.colorVideos,
                      text: context.l10n.rankingVideosTip),
                  const SizedBox(height: 16),
                  _LastWeekWinnersSection(lastWinnersAsync: lastWinnersAsync),
                  const SizedBox(height: 24),
                ], // children Column interno
              ), // Column interno
            ), // Padding
          ], // children Column externo
        ), // Column externo
      ), // SingleChildScrollView
    ); // RefreshIndicator
  }
}

class _EmptyPodiumSlot extends StatelessWidget {
  final double height;
  final String label;
  final String emoji;
  final Color color;
  const _EmptyPodiumSlot(
      {required this.height,
      required this.label,
      required this.emoji,
      required this.color});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.fondoCardBorde,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: AppColors.textoDeshabilitado, size: 24),
          ),
          const SizedBox(height: 6),
          Container(
            width: 72,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Center(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textoDeshabilitado,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ],
      );
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _TipRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 13)),
        ]),
      );
}

// ── Lista con datos reales (con animación staggered) ─────────────
class _RankList extends StatefulWidget {
  final List<RankEntry> entries;
  final String? myId;
  final AsyncValue<({int rank, int coins})?> myRankAsync;
  final AsyncValue<List<LastWinner>> lastWinnersAsync;
  final VoidCallback onRefresh;
  const _RankList(
      {required this.entries,
      required this.myId,
      required this.myRankAsync,
      required this.lastWinnersAsync,
      required this.onRefresh});

  @override
  State<_RankList> createState() => _RankListState();
}

class _RankListState extends State<_RankList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top3 = widget.entries.take(3).toList();
    final rest = widget.entries.skip(3).toList();
    final inTop = widget.entries.any((e) => e.id == widget.myId);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.azulPrimario,
            onRefresh: () async => widget.onRefresh(),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Header ──────────────────────────────────────────
                _HeroHeader(onRefresh: widget.onRefresh),

                // ── Pódium top 3 ────────────────────────────────────
                _animatedItem(
                  index: 0,
                  child: _Podium(top3: top3, myId: widget.myId),
                ),

                // ── Posiciones 4-50 ─────────────────────────────────
                if (rest.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          height: 1,
                          width: 24,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.rankingPositions(widget.entries.length),
                          style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...rest.asMap().entries.map((e) => _animatedItem(
                        index: e.key + 1,
                        child: _RankRow(
                          entry: e.value,
                          isMe: e.value.id == widget.myId,
                        ),
                      )),
                ],

                // ── Ganadores semana pasada ──────────────────────────
                _LastWeekWinnersSection(
                    lastWinnersAsync: widget.lastWinnersAsync),
                const SizedBox(height: 80),
              ],
            ), // ListView
          ), // RefreshIndicator
        ),
        if (!inTop)
          widget.myRankAsync.when(
            loading: () => const _MyPositionBarLoading(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) => data == null
                ? const SizedBox.shrink()
                : _MyPositionBar(rank: data.rank, coins: data.coins),
          ),
      ],
    );
  }

  Widget _animatedItem({required int index, required Widget child}) {
    final delay = (index * 60).clamp(0, 600);
    final start = delay / 900.0;
    final end = (start + 0.55).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, __) => FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

// ── Pódium ────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<RankEntry> top3;
  final String? myId;
  const _Podium({required this.top3, required this.myId});

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 0),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fondoCardBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Etiqueta pódium
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 6),
              Text(context.l10n.rankingTop3Label,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (second != null)
                _PodiumSlot(
                  entry: second,
                  isMe: second.id == myId,
                  emoji: '🥈',
                  rank: 2,
                  avatarSize: 54,
                  pedestalH: 68,
                  pedestalColors: const [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
                )
              else
                const SizedBox(width: 90),
              if (first != null)
                _PodiumSlot(
                  entry: first,
                  isMe: first.id == myId,
                  emoji: '🥇',
                  rank: 1,
                  avatarSize: 68,
                  pedestalH: 88,
                  pedestalColors: const [Color(0xFFFFD700), Color(0xFFF59E0B)],
                  isCrown: true,
                )
              else
                const SizedBox(width: 90),
              if (third != null)
                _PodiumSlot(
                  entry: third,
                  isMe: third.id == myId,
                  emoji: '🥉',
                  rank: 3,
                  avatarSize: 46,
                  pedestalH: 50,
                  pedestalColors: const [Color(0xFFFCA16C), Color(0xFFEA8040)],
                )
              else
                const SizedBox(width: 90),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final RankEntry entry;
  final bool isMe;
  final String emoji;
  final int rank;
  final double avatarSize;
  final double pedestalH;
  final List<Color> pedestalColors;
  final bool isCrown;

  const _PodiumSlot({
    required this.entry,
    required this.isMe,
    required this.emoji,
    required this.rank,
    required this.avatarSize,
    required this.pedestalH,
    required this.pedestalColors,
    this.isCrown = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Corona
          if (isCrown)
            const Text('👑', style: TextStyle(fontSize: 18))
          else
            const SizedBox(height: 18),

          const SizedBox(height: 4),

          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        pedestalColors[0].withValues(alpha: 0.25),
                        pedestalColors[1].withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isMe ? AppColors.azulOscuro : pedestalColors[0],
                width: 2.5,
              ),
              boxShadow: isCrown
                  ? [
                      BoxShadow(
                        color: pedestalColors[0].withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(entry.initials,
                  style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textoPrimario,
                      fontSize: avatarSize * 0.36,
                      fontWeight: FontWeight.w900)),
            ),
          ),

          const SizedBox(height: 6),

          // Nombre
          SizedBox(
            width: 92,
            child: Text(entry.username,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color:
                        isMe ? AppColors.azulPrimario : AppColors.textoPrimario,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          const SizedBox(height: 3),

          // Monedas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.fondoPrincipal,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.fondoCardBorde),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 11),
                const SizedBox(width: 3),
                Text(entry.weeklyCoins.formatted,
                    style: TextStyle(
                        color: isMe
                            ? AppColors.azulPrimario
                            : AppColors.textoPrimario,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Pedestal con gradiente
          Container(
            width: 84,
            height: pedestalH,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: pedestalColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                Text('#${entry.rank}',
                    style: TextStyle(
                        color: pedestalColors[0].computeLuminance() > 0.4
                            ? AppColors.textoPrimario
                            : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ],
            ),
          ),
        ],
      );
}

// ── Fila posición 4–50 ───────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final RankEntry entry;
  final bool isMe;
  const _RankRow({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final badgeColor = _rankBadgeColor(entry.rank);
    final badgeBg = _rankBadgeBg(entry.rank);
    final isTop10 = entry.rank <= 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.azulPrimario.withValues(alpha: 0.07)
            : AppColors.fondoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.azulPrimario.withValues(alpha: 0.35)
              : isTop10
                  ? AppColors.azulPrimario.withValues(alpha: 0.12)
                  : AppColors.fondoCardBorde,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.azulPrimario.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Row(children: [
        // Badge de posición
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isMe ? AppColors.azulPrimario : badgeBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMe
                  ? AppColors.azulOscuro
                  : badgeColor.withValues(alpha: 0.30),
            ),
          ),
          child: Center(
            child: Text('#${entry.rank}',
                style: TextStyle(
                    color: isMe ? Colors.white : badgeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: entry.rank >= 10 ? 11 : 13)),
          ),
        ),

        const SizedBox(width: 10),

        // Avatar
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      AppColors.fondoPrincipal,
                      AppColors.fondoPrincipal,
                    ],
                  ),
            shape: BoxShape.circle,
            border: Border.all(
              color: isMe ? AppColors.azulOscuro : AppColors.fondoCardBorde,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(entry.initials,
                style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textoSecundario,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ),
        ),

        const SizedBox(width: 10),

        // Info central
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Flexible(
                  child: Text(entry.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isMe
                              ? AppColors.azulPrimario
                              : AppColors.textoPrimario,
                          fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14)),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.azulPrimario,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(context.l10n.rankingYou,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              if (entry.streakDays > 0) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(context.l10n.rankingStreakDays(entry.streakDays),
                        style: const TextStyle(
                            color: Colors.deepOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Monedas
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 13),
                const SizedBox(width: 4),
                Text(entry.weeklyCoins.formatted,
                    style: TextStyle(
                        color: isMe
                            ? AppColors.azulPrimario
                            : AppColors.textoPrimario,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
            Text('\$${entry.usd.toStringAsFixed(2)} USD',
                style: const TextStyle(
                    color: AppColors.textoDeshabilitado, fontSize: 10)),
          ],
        ),
      ]),
    );
  }
}

// ── Tarjeta "Mi posición" (estado vacío) ─────────────────────────
class _MyPositionCard extends StatelessWidget {
  final int rank;
  final int coins;
  const _MyPositionCard({required this.rank, required this.coins});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.azulPrimario.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.azulPrimario.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.rankingMyPosition,
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 12)),
                Text(context.l10n.rankingEarnToClimb,
                    style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 11),
                  const SizedBox(width: 3),
                  Text(coins.formatted,
                      style: const TextStyle(
                          color: AppColors.azulPrimario,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                  Text(' ${context.l10n.rankingThisWeek}',
                      style: const TextStyle(
                          color: Color.fromARGB(255, 56, 56, 56),
                          fontSize: 11)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.azulPrimario.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text('#$rank',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22)),
          ),
        ]),
      );
}

// ── Barra inferior fija ───────────────────────────────────────────
class _MyPositionBar extends StatelessWidget {
  final int rank;
  final int coins;
  const _MyPositionBar({required this.rank, required this.coins});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.fondoCard,
          border:
              const Border(top: BorderSide(color: AppColors.fondoCardBorde)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(13),
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.rankingMyPositionBar,
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 11)),
                Text(context.l10n.rankingKeepPlaying,
                    style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Row(children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 10),
                  const SizedBox(width: 3),
                  Text(coins.formatted,
                      style: const TextStyle(
                          color: AppColors.azulPrimario,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                  Text(' ${context.l10n.rankingThisWeek}',
                      style: const TextStyle(
                          color: Color.fromARGB(255, 78, 78, 78),
                          fontSize: 10)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.azulPrimario.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text('#$rank',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
          ),
        ]),
      );
}

class _MyPositionBarLoading extends StatelessWidget {
  const _MyPositionBarLoading();

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.fondoCard,
          border: Border(top: BorderSide(color: AppColors.fondoCardBorde)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: AppColors.azulPrimario, strokeWidth: 2),
          ),
        ),
      );
}

// ── Sección ganadores semana pasada ──────────────────────────────
class _LastWeekWinnersSection extends StatelessWidget {
  final AsyncValue<List<LastWinner>> lastWinnersAsync;
  const _LastWeekWinnersSection({required this.lastWinnersAsync});

  @override
  Widget build(BuildContext context) {
    return lastWinnersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (winners) {
        if (winners.isEmpty) return const SizedBox.shrink();
        final medalEmoji = ['🥇', '🥈', '🥉'];
        final medalColors = [
          const Color(0xFFFFD700),
          const Color(0xFFCBD5E1),
          const Color(0xFFFCA16C),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Separador título
              Row(children: [
                Container(
                    height: 1,
                    width: 20,
                    color: const Color.fromARGB(255, 0, 0, 0)),
                const SizedBox(width: 8),
                Text(context.l10n.rankingLastWinnersTitle,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 9, 9, 9),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const SizedBox(width: 8),
                Expanded(
                    child: Container(
                        height: 1, color: const Color.fromARGB(255, 0, 0, 0))),
              ]),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.fondoCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.fondoCardBorde),
                ),
                child: Column(
                  children: winners.asMap().entries.map((e) {
                    final i = e.key;
                    final w = e.value;
                    final emoji = medalEmoji[i];
                    final color = medalColors[i];
                    final isLast = i == winners.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Text(emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: color.withValues(alpha: 0.35)),
                              ),
                              child: Center(
                                child: Text(w.initials,
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(w.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textoPrimario,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                                  const SizedBox(width: 3),
                                  Text('+${w.prize.formatted}',
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15)),
                                ]),
                                Text(context.l10n.rankingLastWinnersPrize,
                                    style: const TextStyle(
                                        color: Color.fromARGB(255, 64, 64, 64),
                                        fontSize: 10)),
                              ],
                            ),
                          ]),
                        ),
                        if (!isLast)
                          const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppColors.fondoCardBorde),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textoDeshabilitado, size: 48),
            const SizedBox(height: 12),
            Text(context.l10n.rankingLoadError,
                style: const TextStyle(color: AppColors.textoSecundario)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: onRetry, child: Text(context.l10n.rankingRetry)),
          ],
        ),
      );
}
