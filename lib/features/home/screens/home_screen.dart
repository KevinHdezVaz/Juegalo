import 'dart:async';
import 'dart:io';
import 'package:cpx_research_sdk_flutter/cpx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/providers/user_provider.dart';
import '../../games/screens/games_screen.dart';
import '../../ranking/screens/ranking_screen.dart';
import '../../surveys/screens/surveys_screen.dart';
import '../../videos/screens/videos_screen.dart';
import '../../wallet/screens/wallet_screen.dart';

const _cpxAppIdAndroid = '32134';
const _cpxAppIdIos = '32848';
final _cpxAppId = Platform.isIOS ? _cpxAppIdIos : _cpxAppIdAndroid;

final activeTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription<String>? _notifSub;
  StreamSubscription<void>? _paymentSub;

  @override
  void initState() {
    super.initState();
    _notifSub = NotificationService.instance.onNavigate.listen((route) {
      if (mounted) context.go(route);
    });
    // Trigger desde notificación de pago (app en bg/fg)
    _paymentSub = NotificationService.instance.onPaymentTapped.listen((_) {
      if (mounted) _maybeRequestReview(fromNotification: true);
    });
    // Trigger al abrir la app — esperar 4s para que Supabase restaure la sesión
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 4));
      _maybeRequestReview();
    });
  }

  /// Muestra el dialog de reseña si el usuario ya recibió al menos un pago
  /// y aún no le hemos pedido que califique la app.
  Future<void> _maybeRequestReview({bool fromNotification = false}) async {
    const kReviewKey = 'review_requested';
    final kReviewDelay = fromNotification
        ? const Duration(milliseconds: 800) // viene de notif → delay corto
        : const Duration(seconds: 3); // apertura normal → espera más

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(kReviewKey) == true) return;

      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      // ¿Tiene algún cashout pagado?
      final result = await Supabase.instance.client
          .from('cashout_requests')
          .select('id')
          .eq('user_id', uid)
          .eq('status', 'paid')
          .limit(1);

      if (result.isEmpty) return;

      await Future.delayed(kReviewDelay);
      if (!mounted) return;

      final inAppReview = InAppReview.instance;
      final available = await inAppReview.isAvailable();
      debugPrint('⭐ [Review] isAvailable=$available | fromNotification=$fromNotification');
      if (available) {
        await inAppReview.requestReview();
        await prefs.setBool(kReviewKey, true);
        debugPrint('✅ [Review] Reseña solicitada correctamente');
      } else {
        // En release desde Play Store/App Store debería funcionar.
        // En dev/debug isAvailable() suele retornar false — es normal.
        debugPrint('⚠️ [Review] No disponible en este entorno (debug/simulador)');
      }
    } catch (e) {
      debugPrint('⚠️ [Review] Error al pedir reseña: $e');
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _paymentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const _HomeScreenBody();
}

class _HomeScreenBody extends ConsumerWidget {
  const _HomeScreenBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final user = ref.watch(userProvider).value;
    final l = context.l10n;

    final hideGames = Platform.isIOS;

    final screens = [
      if (!hideGames) const GamesScreen(),
      const SurveysScreen(),
      const VideosScreen(),
      const RankingScreen(),
      const WalletScreen(),
    ];

    final tabs = [
      if (!hideGames)
        _TabItem(
            icon: Icons.sports_esports_rounded,
            label: l.homeTabGames,
            color: AppColors.colorJuegos),
      _TabItem(
          icon: Icons.assignment_outlined,
          label: l.homeTabSurveys,
          color: AppColors.azulPrimario),
      _TabItem(
          icon: Icons.play_circle_outline,
          label: l.homeTabVideos,
          color: AppColors.colorVideos),
      _TabItem(
          icon: Icons.leaderboard_rounded,
          label: l.homeTabRanking,
          color: AppColors.dorado),
      _TabItem(
          icon: Icons.account_balance_wallet_outlined,
          label: l.homeTabWallet,
          color: AppColors.azulPrimario),
    ];

    final walletTabIndex = hideGames ? 3 : 4;
    final safeTab = activeTab.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoCard,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.azulPrimario.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('JUEGALO',
                style: TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1)),
          ],
        ),
        actions: [
          if (user != null)
            GestureDetector(
              onTap: () =>
                  ref.read(activeTabProvider.notifier).state = walletTabIndex,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.azulPrimario.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.azulPrimario.withValues(alpha: 0.30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: AppColors.dorado, size: 16),
                    const SizedBox(width: 5),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.coins.formatted,
                          style: const TextStyle(
                            color: AppColors.azulPrimario,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '${user.balanceUsd.fmtUsd} USD',
                          style: const TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 9,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline,
                color: AppColors.textoSecundario),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: Stack(
        children: [
          screens[safeTab],
          if (user != null)
            CPXResearch(
              config: CPXConfig(
                appID: _cpxAppId,
                userID: user.id,
                accentColor: AppColors.azulPrimario,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _NavBar(
        tabs: tabs,
        currentIndex: safeTab,
        onTap: (i) => ref.read(activeTabProvider.notifier).state = i,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Nav Bar — igual en iOS y Android
// ─────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.fondoCard,
        border: Border(top: BorderSide(color: AppColors.fondoCardBorde)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: AppColors.fondoCard,
          selectedItemColor: tabs[currentIndex].color,
          unselectedItemColor: const Color(0xFF475569),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          iconSize: 24,
          items: tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final String label;
  final Color color;
  const _TabItem(
      {required this.icon, required this.label, required this.color});
}
