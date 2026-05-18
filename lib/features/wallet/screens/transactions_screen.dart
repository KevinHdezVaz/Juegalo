import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/widgets/app_error_widget.dart';

// ── Filtros ──────────────────────────────────────────────────────
enum TxFilter { all, video, survey, bonus, cashout }

extension TxFilterLabel on TxFilter {
  String label(BuildContext context) => switch (this) {
        TxFilter.all     => context.l10n.txFilterAll,
        TxFilter.video   => context.l10n.txFilterVideos,
        TxFilter.survey  => context.l10n.txFilterSurveys,
        TxFilter.bonus   => context.l10n.txFilterBonus,
        TxFilter.cashout => context.l10n.txFilterCashout,
      };
}

// ── Estado ───────────────────────────────────────────────────────
class TxHistoryData {
  final List<Map<String, dynamic>> items;
  final bool hasMore;
  final bool loadingMore;

  const TxHistoryData({
    this.items = const [],
    this.hasMore = true,
    this.loadingMore = false,
  });

  TxHistoryData copyWith({
    List<Map<String, dynamic>>? items,
    bool? hasMore,
    bool? loadingMore,
  }) =>
      TxHistoryData(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

const _kPageSize = 25;

// ── Notifier (uno por filtro, via .family) ───────────────────────
class TxHistoryNotifier
    extends StateNotifier<AsyncValue<TxHistoryData>> {
  final TxFilter filter;

  TxHistoryNotifier(this.filter) : super(const AsyncValue.loading()) {
    _fetch(reset: true);
  }

  Future<void> loadMore() async {
    final data = state.valueOrNull;
    if (data == null || !data.hasMore || data.loadingMore) return;
    state = AsyncValue.data(data.copyWith(loadingMore: true));
    await _fetch(reset: false);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _fetch(reset: true);
  }

  Future<void> _fetch({required bool reset}) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      state = const AsyncValue.data(TxHistoryData(hasMore: false));
      return;
    }

    final current = state.valueOrNull;
    final from = reset ? 0 : (current?.items.length ?? 0);
    final to = from + _kPageSize - 1;

    try {
      final db = Supabase.instance.client;
      List<Map<String, dynamic>> rows;

      switch (filter) {
        case TxFilter.bonus:
          rows = List<Map<String, dynamic>>.from(
            await db.from('transactions').select()
                .eq('user_id', uid).eq('type', 'bonus')
                .order('created_at', ascending: false).range(from, to),
          );
        case TxFilter.cashout:
          rows = List<Map<String, dynamic>>.from(
            await db.from('transactions').select()
                .eq('user_id', uid).eq('type', 'cashout')
                .order('created_at', ascending: false).range(from, to),
          );
        case TxFilter.video:
          rows = List<Map<String, dynamic>>.from(
            await db.from('transactions').select()
                .eq('user_id', uid).eq('source', 'video')
                .order('created_at', ascending: false).range(from, to),
          );
        case TxFilter.survey:
          rows = List<Map<String, dynamic>>.from(
            await db.from('transactions').select()
                .eq('user_id', uid).eq('source', 'survey')
                .order('created_at', ascending: false).range(from, to),
          );
        case TxFilter.all:
          rows = List<Map<String, dynamic>>.from(
            await db.from('transactions').select()
                .eq('user_id', uid)
                .order('created_at', ascending: false).range(from, to),
          );
      }

      final prev = reset ? <Map<String, dynamic>>[] : (current?.items ?? []);
      state = AsyncValue.data(TxHistoryData(
        items: [...prev, ...rows],
        hasMore: rows.length >= _kPageSize,
        loadingMore: false,
      ));
    } catch (e, st) {
      if (reset) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.data(
          (current ?? const TxHistoryData())
              .copyWith(loadingMore: false, hasMore: false),
        );
      }
    }
  }
}

// Un provider por cada filtro (autoDispose = se libera al salir)
final txHistoryProvider = StateNotifierProvider.autoDispose
    .family<TxHistoryNotifier, AsyncValue<TxHistoryData>, TxFilter>(
  (_, filter) => TxHistoryNotifier(filter),
);

// ── Screen ───────────────────────────────────────────────────────
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  static const _filters = TxFilter.values; // all, video, survey, bonus, cashout
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _filters.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.txHistoryTitle,
          style: const TextStyle(
            color: AppColors.textoPrimario,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textoPrimario),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.fondoCardBorde),
              ),
            ),
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.azulPrimario,
              indicatorWeight: 2.5,
              labelColor: AppColors.azulPrimario,
              unselectedLabelColor: AppColors.textoSecundario,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: _filters
                  .map((f) => Tab(text: f.label(context)))
                  .toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _filters
            .map((f) => _TxFilterPage(filter: f))
            .toList(),
      ),
    );
  }
}

// ── Página por filtro ────────────────────────────────────────────
class _TxFilterPage extends ConsumerWidget {
  final TxFilter filter;
  const _TxFilterPage({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(txHistoryProvider(filter));
    final notifier = ref.read(txHistoryProvider(filter).notifier);

    return asyncState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.azulPrimario),
      ),
      error: (_, __) => AppErrorWidget(
        message: context.l10n.txLoadError,
        onRetry: notifier.refresh,
      ),
      data: (data) {
        final grouped = _buildGrouped(data.items, context);

        return RefreshIndicator(
          color: AppColors.azulPrimario,
          onRefresh: notifier.refresh,
          child: grouped.isEmpty
              ? _EmptyState(filter: filter)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: grouped.length + 1, // +1 para el footer
                  itemBuilder: (context, i) {
                    if (i < grouped.length) return grouped[i];
                    // Footer: cargar más / spinner
                    if (data.loadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.azulPrimario,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    if (data.hasMore) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton(
                          onPressed: notifier.loadMore,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.azulPrimario,
                            side: const BorderSide(
                                color: AppColors.azulPrimario),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(context.l10n.txLoadMore),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
        );
      },
    );
  }

  List<Widget> _buildGrouped(
      List<Map<String, dynamic>> items, BuildContext context) {
    final result = <Widget>[];
    String? lastGroup;
    for (final tx in items) {
      final group = _groupLabel(tx['created_at'] as String?, context);
      if (group != lastGroup) {
        result.add(_DateHeader(label: group));
        lastGroup = group;
      }
      result.add(_TxRow(tx: tx));
    }
    return result;
  }

  String _groupLabel(String? raw, BuildContext context) {
    if (raw == null) return context.l10n.txGroupOlder;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return context.l10n.txGroupOlder;
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return context.l10n.txGroupToday;
    if (diff == 1) return context.l10n.txGroupYesterday;
    if (diff <= 7) return context.l10n.txGroupThisWeek;
    if (diff <= 30) return context.l10n.txGroupThisMonth;
    return context.l10n.txGroupOlder;
  }
}

// ── Estado vacío ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final TxFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: AppColors.textoDeshabilitado, size: 48),
                const SizedBox(height: 12),
                Text(
                  filter == TxFilter.all
                      ? context.l10n.txEmpty
                      : context.l10n.txEmptyFilter,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header de grupo ──────────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );
}

// ── Fila de transacción ──────────────────────────────────────────
class _TxRow extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final coins = tx['coins'] as int? ?? 0;
    final source = tx['source'] as String? ?? '';
    final type = tx['type'] as String? ?? '';
    final desc = tx['description'] as String? ?? source;
    final isCredit = coins >= 0;
    final timeStr = _fmt(tx['created_at'] as String?);
    final (icon, color) = _iconColor(source, type, isCredit);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc,
                    style: const TextStyle(
                      color: AppColors.textoPrimario,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(timeStr,
                      style: const TextStyle(
                          color: AppColors.textoSecundario, fontSize: 11)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : ''}${coins.formatted}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _iconColor(String source, String type, bool isCredit) {
    if (type == 'cashout' || source == 'cashout') {
      return (Icons.arrow_upward_rounded, AppColors.alerta);
    }
    return switch (source) {
      'video'       => (Icons.play_circle_outline_rounded, AppColors.colorVideos),
      'survey'      => (Icons.assignment_outlined, AppColors.colorEncuestas),
      'daily_bonus' => (Icons.local_fire_department_rounded, Colors.orange),
      'goal_bonus'  => (Icons.flag_rounded, AppColors.verdePrimario),
      'referral'    => (Icons.people_outline_rounded, AppColors.colorJuegos),
      'migration'   => (Icons.swap_horiz_rounded, AppColors.textoSecundario),
      _ => isCredit
          ? (Icons.monetization_on_outlined, AppColors.verdePrimario)
          : (Icons.remove_circle_outline_rounded, AppColors.error),
    };
  }

  String _fmt(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
