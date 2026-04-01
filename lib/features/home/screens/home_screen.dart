import 'package:cpx_research_sdk_flutter/cpx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_provider.dart';
import '../../games/screens/games_screen.dart';
import '../../ranking/screens/ranking_screen.dart';
import '../../surveys/screens/surveys_screen.dart';
import '../../videos/screens/videos_screen.dart';
import '../../wallet/screens/wallet_screen.dart';

const _cpxAppId = '32134';

final activeTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _tabs = [
    _TabItem(
        icon: Icons.sports_esports_rounded,
        label: 'Juegos',
        color: AppColors.colorJuegos),
    _TabItem(
        icon: Icons.assignment_outlined,
        label: 'Encuestas',
        color: AppColors.azulPrimario),
    _TabItem(
        icon: Icons.play_circle_outline,
        label: 'Videos',
        color: AppColors.colorVideos),
    _TabItem(
        icon: Icons.leaderboard_rounded,
        label: 'Ranking',
        color: AppColors.dorado),
    _TabItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Cobrar',
        color: AppColors.azulPrimario),
  ];

  static const _screens = [
    GamesScreen(),
    SurveysScreen(),
    VideosScreen(),
    RankingScreen(),
    WalletScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final user = ref.watch(userProvider).value;

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
              onTap: () => ref.read(activeTabProvider.notifier).state = 4,
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
                    Text(
                      '${user.coins}',
                      style: const TextStyle(
                        color: AppColors.azulPrimario,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
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
      // ── CPXResearch overlay global (requerido para browser y cards) ──
      body: Stack(
        children: [
          _screens[activeTab],
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.fondoCard,
          border: Border(top: BorderSide(color: AppColors.fondoCardBorde)),
        ),
        child: BottomNavigationBar(
          currentIndex: activeTab,
          onTap: (i) => ref.read(activeTabProvider.notifier).state = i,
          backgroundColor: AppColors.fondoCard,
          selectedItemColor: _tabs[activeTab].color,
          unselectedItemColor: AppColors.textoDeshabilitado,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: _tabs
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

class _TabItem {
  final IconData icon;
  final String label;
  final Color color;
  const _TabItem(
      {required this.icon, required this.label, required this.color});
}
