import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

// ── Modelo ────────────────────────────────────────────────────────
class RankEntry {
  final int    rank;
  final String id;
  final String username;
  final String countryCode;
  final int    weeklyCoins;
  final int    streakDays;

  const RankEntry({
    required this.rank,
    required this.id,
    required this.username,
    required this.countryCode,
    required this.weeklyCoins,
    required this.streakDays,
  });

  factory RankEntry.fromJson(Map<String, dynamic> j, {required int rank}) =>
      RankEntry(
        rank:        rank,
        id:          j['id'] as String,
        username:    j['username'] as String? ?? 'Jugador',
        countryCode: j['country_code'] as String? ?? '',
        weeklyCoins: j['weekly_coins'] as int? ?? 0,
        streakDays:  j['streak_days'] as int? ?? 0,
      );

  double get usd => weeklyCoins / 1000.0;
  String get initials => username.isNotEmpty ? username[0].toUpperCase() : '?';
}

// ── Providers ─────────────────────────────────────────────────────
final rankingProvider = FutureProvider.autoDispose<List<RankEntry>>((ref) async {
  final rows = await Supabase.instance.client
      .from('users')
      .select('id, username, country_code, weekly_coins, streak_days')
      .gt('weekly_coins', 0)
      .order('weekly_coins', ascending: false)
      .limit(100);
  return List.generate(
    rows.length,
    (i) => RankEntry.fromJson(rows[i], rank: i + 1),
  );
});

final myWeeklyRankProvider = FutureProvider.autoDispose<int?>((ref) async {
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
  return (res.count) + 1;
});

// ── Utilidades ────────────────────────────────────────────────────
String _flag(String code) {
  if (code.length != 2) return '';
  final base = 0x1F1E6;
  final a = code.toUpperCase().codeUnitAt(0) - 65 + base;
  final b = code.toUpperCase().codeUnitAt(1) - 65 + base;
  return String.fromCharCode(a) + String.fromCharCode(b);
}

String _countdown() {
  final now  = DateTime.now().toUtc();
  final days = (8 - now.weekday) % 7;
  final next = DateTime.utc(now.year, now.month, now.day + (days == 0 ? 7 : days));
  final diff = next.difference(now);
  final d = diff.inDays;
  final h = diff.inHours % 24;
  final m = diff.inMinutes % 60;
  if (d > 0) return '${d}d ${h}h ${m}m';
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

// ── Pantalla ──────────────────────────────────────────────────────
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider);
    final myRankAsync  = ref.watch(myWeeklyRankProvider);
    final myId         = Supabase.instance.client.auth.currentUser?.id;

    return rankingAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.azulPrimario)),
      error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(rankingProvider)),
      data: (entries) => _RankingBody(
        entries:      entries,
        myId:         myId,
        myRankAsync:  myRankAsync,
        onRefresh:    () {
          ref.invalidate(rankingProvider);
          ref.invalidate(myWeeklyRankProvider);
        },
      ),
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────
class _RankingBody extends StatelessWidget {
  final List<RankEntry> entries;
  final String? myId;
  final AsyncValue<int?> myRankAsync;
  final VoidCallback onRefresh;

  const _RankingBody({
    required this.entries,
    required this.myId,
    required this.myRankAsync,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = entries.isEmpty;

    return Column(
      children: [
        // ── Header hero ──────────────────────────────────────────
        _HeroHeader(onRefresh: onRefresh),

        // ── Lista ────────────────────────────────────────────────
        Expanded(
          child: isEmpty
              ? _EmptyState(myRankAsync: myRankAsync)
              : _RankList(entries: entries, myId: myId, myRankAsync: myRankAsync),
        ),
      ],
    );
  }
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
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
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
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ranking Semanal',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 0.3)),
                    Text('Top jugadores de la semana',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              // Countdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text(_countdown(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
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
              Expanded(child: _PrizeCard(medal: '🥇', pos: '#1', coins: '5,000', usd: '\$5',
                  color: const Color(0xFFFFD700))),
              const SizedBox(width: 8),
              Expanded(child: _PrizeCard(medal: '🥈', pos: '#2', coins: '2,000', usd: '\$2',
                  color: const Color(0xFFD0D8E8))),
              const SizedBox(width: 8),
              Expanded(child: _PrizeCard(medal: '🥉', pos: '#3', coins: '1,000', usd: '\$1',
                  color: const Color(0xFFCD9B6A))),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white54, size: 11),
              SizedBox(width: 4),
              Text('Se reinicia cada lunes',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final String medal;
  final String pos;
  final String coins;
  final String usd;
  final Color  color;
  const _PrizeCard(
      {required this.medal,
      required this.pos,
      required this.coins,
      required this.usd,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(medal, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 3),
                    Text(coins,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ],
                ),
                Text('$usd · $pos',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      );
}

// ── Estado vacío ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final AsyncValue<int?> myRankAsync;
  const _EmptyState({required this.myRankAsync});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Pódium vacío decorativo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.fondoCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.fondoCardBorde),
            ),
            child: Column(
              children: [
                const Text('¡Sé el primero!',
                    style: TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text(
                  'Nadie ha ganado monedas esta semana.\nEl ranking se llena conforme los jugadores compiten.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 13,
                      height: 1.5),
                ),
                const SizedBox(height: 24),
                // Pódium vacío
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _EmptyPodiumSlot(height: 60,  label: '#2', color: const Color(0xFFE2E8F0)),
                    _EmptyPodiumSlot(height: 80, label: '#1', color: const Color(0xFFFEF9C3)),
                    _EmptyPodiumSlot(height: 44,  label: '#3', color: const Color(0xFFFEF3C7)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Tu posición
          myRankAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (rank) => rank == null
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.azulPrimario.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.azulPrimario.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tu posición actual',
                                style: TextStyle(
                                    color: AppColors.textoSecundario,
                                    fontSize: 12)),
                            Text('Gana monedas para subir',
                                style: TextStyle(
                                    color: AppColors.textoPrimario,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      Text('#$rank',
                          style: const TextStyle(
                              color: AppColors.azulPrimario,
                              fontWeight: FontWeight.w900,
                              fontSize: 22)),
                    ]),
                  ),
          ),
          const SizedBox(height: 16),
          // Tips
          _TipRow(icon: Icons.sports_esports_rounded,
              color: AppColors.colorJuegos,
              text: 'Instala juegos y completa misiones'),
          const SizedBox(height: 8),
          _TipRow(icon: Icons.assignment_outlined,
              color: AppColors.colorEncuestas,
              text: 'Completa encuestas y gana rápido'),
          _TipRow(icon: Icons.play_circle_outline_rounded,
              color: AppColors.colorVideos,
              text: 'Ve 20 videos diarios para acumular'),
        ],
      ),
    );
  }
}

class _EmptyPodiumSlot extends StatelessWidget {
  final double height;
  final String label;
  final Color  color;
  const _EmptyPodiumSlot(
      {required this.height, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.fondoCardBorde,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fondoCardBorde, width: 2),
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: AppColors.textoDeshabilitado, size: 22),
          ),
          const SizedBox(height: 6),
          Container(
            width: 72, height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(6),
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
            width: 36, height: 36,
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

// ── Lista con datos reales ────────────────────────────────────────
class _RankList extends StatelessWidget {
  final List<RankEntry> entries;
  final String? myId;
  final AsyncValue<int?> myRankAsync;
  const _RankList(
      {required this.entries, required this.myId, required this.myRankAsync});

  @override
  Widget build(BuildContext context) {
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();
    final inTop = entries.any((e) => e.id == myId);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Pódium top 3
              _Podium(top3: top3, myId: myId),
              if (rest.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('POSICIONES 4 – ${entries.length}',
                      style: const TextStyle(
                          color: AppColors.textoDeshabilitado,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
                ...rest.map((e) => _RankRow(entry: e, isMe: e.id == myId)),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
        if (!inTop) _MyPositionBar(myRankAsync: myRankAsync),
      ],
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
    final first  = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third  = top3.length > 2 ? top3[2] : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fondoCardBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            _PodiumSlot(entry: second, isMe: second.id == myId,
                medal: '🥈', avatarSize: 52, pedestalH: 64,
                pedestalColor: const Color(0xFFCBD5E1))
          else const SizedBox(width: 90),
          if (first != null)
            _PodiumSlot(entry: first, isMe: first.id == myId,
                medal: '🥇', avatarSize: 66, pedestalH: 84,
                pedestalColor: const Color(0xFFFCD34D))
          else const SizedBox(width: 90),
          if (third != null)
            _PodiumSlot(entry: third, isMe: third.id == myId,
                medal: '🥉', avatarSize: 44, pedestalH: 48,
                pedestalColor: const Color(0xFFFCA16C))
          else const SizedBox(width: 90),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final RankEntry entry;
  final bool isMe;
  final String medal;
  final double avatarSize;
  final double pedestalH;
  final Color pedestalColor;
  const _PodiumSlot({
    required this.entry, required this.isMe, required this.medal,
    required this.avatarSize, required this.pedestalH,
    required this.pedestalColor,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medal, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Container(
            width: avatarSize, height: avatarSize,
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.azulPrimario
                  : AppColors.fondoPrincipal,
              shape: BoxShape.circle,
              border: Border.all(
                color: isMe ? AppColors.azulOscuro : AppColors.fondoCardBorde,
                width: 2.5,
              ),
            ),
            child: Center(
              child: Text(entry.initials,
                  style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textoSecundario,
                      fontSize: avatarSize * 0.38,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 88,
            child: Text(entry.username,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isMe ? AppColors.azulPrimario : AppColors.textoPrimario,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          if (entry.countryCode.isNotEmpty)
            Text(_flag(entry.countryCode),
                style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 3),
              Text('${entry.weeklyCoins}',
                  style: TextStyle(
                      color: isMe ? AppColors.azulPrimario : AppColors.textoPrimario,
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 80, height: pedestalH,
            decoration: BoxDecoration(
              color: pedestalColor,
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text('#${entry.rank}',
                  style: TextStyle(
                      color: pedestalColor.computeLuminance() > 0.4
                          ? AppColors.textoPrimario
                          : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
            ),
          ),
        ],
      );
}

// ── Fila posición 4–100 ───────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final RankEntry entry;
  final bool isMe;
  const _RankRow({required this.entry, required this.isMe});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.azulPrimario.withValues(alpha: 0.07)
              : AppColors.fondoCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe
                ? AppColors.azulPrimario.withValues(alpha: 0.30)
                : AppColors.fondoCardBorde,
          ),
        ),
        child: Row(children: [
          SizedBox(
            width: 34,
            child: Text('#${entry.rank}',
                style: TextStyle(
                    color: isMe
                        ? AppColors.azulPrimario
                        : AppColors.textoSecundario,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.azulPrimario
                  : AppColors.fondoPrincipal,
              shape: BoxShape.circle,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (entry.countryCode.isNotEmpty) ...[
                    Text(_flag(entry.countryCode),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(entry.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: isMe
                                ? AppColors.azulPrimario
                                : AppColors.textoPrimario,
                            fontWeight:
                                isMe ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 14)),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.azulPrimario,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('TÚ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
                if (entry.streakDays > 0)
                  Text('🔥 ${entry.streakDays} días',
                      style: const TextStyle(
                          color: AppColors.textoDeshabilitado, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text('${entry.weeklyCoins}',
                      style: TextStyle(
                          color: isMe
                              ? AppColors.azulPrimario
                              : AppColors.textoPrimario,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
              Text('\$${entry.usd.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.textoDeshabilitado, fontSize: 10)),
            ],
          ),
        ]),
      );
}

// ── Barra inferior ────────────────────────────────────────────────
class _MyPositionBar extends StatelessWidget {
  final AsyncValue<int?> myRankAsync;
  const _MyPositionBar({required this.myRankAsync});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.fondoCard,
          border: Border(top: BorderSide(color: AppColors.fondoCardBorde)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu posición esta semana',
                    style: TextStyle(
                        color: AppColors.textoSecundario, fontSize: 12)),
                Text('¡Sigue jugando para subir!',
                    style: TextStyle(
                        color: AppColors.textoPrimario,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
          myRankAsync.when(
            loading: () => const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.azulPrimario, strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
            data: (rank) => rank == null
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.azulPrimario,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('#$rank',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                  ),
          ),
        ]),
      );
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
            const Text('No se pudo cargar el ranking',
                style: TextStyle(color: AppColors.textoSecundario)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
}
