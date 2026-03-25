import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/providers/user_provider.dart';
import '../../games/screens/games_screen.dart';
import '../../surveys/screens/surveys_screen.dart';
import '../../videos/screens/videos_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../widgets/balance_card.dart';
import '../widgets/daily_goal_bar.dart';

// Índice del tab activo
final activeTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _tabs = [
    _TabItem(icon: Icons.sports_esports_rounded, label: 'Juegos',    color: AppColors.colorJuegos),
    _TabItem(icon: Icons.assignment_outlined,    label: 'Encuestas', color: AppColors.colorEncuestas),
    _TabItem(icon: Icons.play_circle_outline,    label: 'Videos',    color: AppColors.colorVideos),
    _TabItem(icon: Icons.account_balance_wallet_outlined, label: 'Cobrar', color: AppColors.colorWallet),
  ];

  static const _screens = [
    GamesScreen(),
    SurveysScreen(),
    VideosScreen(),
    WalletScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final user      = ref.watch(userProvider).value;

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipal,
        title: Row(
          children: [
            const Icon(Icons.sports_esports_rounded,
                color: AppColors.verdePrimario, size: 22),
            const SizedBox(width: 8),
            const Text('JUÉGALO',
                style: TextStyle(
                    color: AppColors.textoPrimario,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1)),
          ],
        ),
        actions: [
          // Balance rápido en appbar
          if (user != null)
            GestureDetector(
              onTap: () => ref.read(activeTabProvider.notifier).state = 3,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.verdePrimario.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.verdePrimario.withValues(alpha: 0.4)),
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
                        color: AppColors.dorado,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.textoSecundario),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner balance + meta diaria (solo en tab home/juegos)
          if (activeTab == 0 && user != null) ...[
            BalanceCard(user: user),
            DailyGoalBar(user: user),
          ],
          Expanded(child: _screens[activeTab]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.fondoCardBorde)),
        ),
        child: BottomNavigationBar(
          currentIndex: activeTab,
          onTap: (i) => ref.read(activeTabProvider.notifier).state = i,
          backgroundColor: AppColors.fondoElevado,
          selectedItemColor: _tabs[activeTab].color,
          unselectedItemColor: AppColors.textoDeshabilitado,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
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
  const _TabItem({required this.icon, required this.label, required this.color});
}
