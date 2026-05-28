import 'dart:async';
import 'dart:math' as math;

import 'package:adjoe/sdk.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../core/utils/number_format_ext.dart';
import '../../../shared/providers/app_config_provider.dart';
import '../../../shared/providers/feature_flags_provider.dart';
import '../../../shared/widgets/feature_disabled_screen.dart';

// ── Modelo de juego ───────────────────────────────────────────────────
class _GameData {
  final String name;
  final String category;
  final List<Color> gradient;
  final IconData fallbackIcon;
  final String imageUrl;
  final int minCoins;
  final int maxCoins;
  final _BadgeType? badge;

  const _GameData({
    required this.name,
    required this.category,
    required this.gradient,
    required this.fallbackIcon,
    required this.imageUrl,
    required this.minCoins,
    required this.maxCoins,
    this.badge,
  });
}

enum _BadgeType { popular, vip, top }

// ── Juegos populares ──────────────────────────────────────────────────
const List<_GameData> _popularGames = [
  _GameData(
    name: 'Coin Master',
    category: 'Casino',
    gradient: [Color(0xFFFF8F00), Color(0xFFFFCA28)],
    fallbackIcon: Icons.monetization_on_rounded,
    imageUrl:
        'https://play-lh.googleusercontent.com/lja_bcS9SXsaK4x_q0rXuiqf3CIIwfy8QveRWfW5MEaAPOST_auDLuzWMyMUrBzi0sI=s256-rw',
    minCoins: 200,
    maxCoins: 800,
    badge: _BadgeType.popular,
  ),
  _GameData(
    name: 'PUBG Mobile',
    category: 'Battle Royale',
    gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    fallbackIcon: Icons.gps_fixed_rounded,
    imageUrl:
        'https://play-lh.googleusercontent.com/zCSGnBtZk0Lmp1BAbyaZfLktDzHmC6oke67qzz3G1lBegAF2asyt5KzXOJ2PVdHDYkU=s256-rw',
    minCoins: 800,
    maxCoins: 2000,
    badge: _BadgeType.vip,
  ),
  _GameData(
    name: 'Candy Crush Saga',
    category: 'Casual',
    gradient: [Color(0xFFC62828), Color(0xFFEF5350)],
    fallbackIcon: Icons.extension_rounded,
    imageUrl:
        'https://play-lh.googleusercontent.com/JvMhIxuwArVmcMReJQB8PIEB1MIQNMGf9j5i914JtkBrHrA55K-nMUIVlYCa7SXAdHtzLtsycEo6NpXeHFxLwvI=s256-rw',
    minCoins: 150,
    maxCoins: 400,
    badge: null,
  ),
  _GameData(
    name: 'Roblox',
    category: 'Sandbox',
    gradient: [Color(0xFF00695C), Color(0xFF26A69A)],
    fallbackIcon: Icons.games_rounded,
    imageUrl:
        'https://play-lh.googleusercontent.com/7cIIPlWm4m7AGqVpEsIfyL-HW4cQla4ucXnfalMft1TMIYQIlf2vqgmthlZgbNAQoaQ=s256-rw',
    minCoins: 300,
    maxCoins: 700,
    badge: _BadgeType.popular,
  ),
  _GameData(
    name: 'Subway Surfers',
    category: 'Runner',
    gradient: [Color(0xFFE65100), Color(0xFFFF9800)],
    fallbackIcon: Icons.directions_run_rounded,
    imageUrl:
        'https://play-lh.googleusercontent.com/rIMQN2JTiHSCj7IezGHkhE39-F66y3Epqlt-iyvveGzT5n0CPOrYDpSePQ7rZBvMJRY=s256-rw',
    minCoins: 100,
    maxCoins: 350,
    badge: null,
  ),
  _GameData(
    name: 'Brawl Stars',
    category: 'Acción',
    gradient: [Color(0xFF283593), Color(0xFF7986CB)],
    fallbackIcon: Icons.flash_on_rounded,
    imageUrl:
        'https://play-lh.googleusercontent.com/IFACylsXgbKgfNXcLbFrzlNhkB6_5LH3IGNA-frTpTPNolzQxL8mI2B_4jnXe5lTCnQYZYIv9zNTQGWn_8QwLA=s256-rw',
    minCoins: 400,
    maxCoins: 1200,
    badge: _BadgeType.top,
  ),
];

// ── Pantalla de Juegos ────────────────────────────────────────────────
class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen>
    with TickerProviderStateMixin {
  bool _loading = false;

  // Carousel
  late final PageController _pageCtrl;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  // Animaciones globales
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _shimmerAnim;
  late final Animation<double> _entranceAnim;

  @override
  void initState() {
    super.initState();

    _pageCtrl = PageController(viewportFraction: 0.82, initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoScrollTimer =
          Timer.periodic(const Duration(milliseconds: 3500), (_) {
        if (!mounted) return;
        if (!_pageCtrl.hasClients) return;
        final next = (_currentPage + 1) % _popularGames.length;
        _pageCtrl.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear),
    );

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _entranceAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _openOfferwall() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final adjoeIdFromConfig = ref.read(appConfigProvider).valueOrNull?.adjoeAppId;
    final appId = (adjoeIdFromConfig != null && adjoeIdFromConfig.isNotEmpty)
        ? adjoeIdFromConfig
        : AppConstants.adjoeAppId;
    if (appId.isEmpty) {
      _showComingSoon();
      return;
    }

    setState(() => _loading = true);
    try {
      final options = PlaytimeOptions(
        userId: uid,
        sdkHash: appId,
        params: PlaytimeParams(placement: 'games_tab'),
      );
      await Playtime.showCatalogWithOptions(options);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.gamesOpenError),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondoElevado,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.l10n.gamesComingSoonTitle,
          style: const TextStyle(
              color: AppColors.textoPrimario, fontWeight: FontWeight.w700),
        ),
        content: Text(
          context.l10n.gamesComingSoonContent,
          style: const TextStyle(color: AppColors.textoSecundario, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.gamesComingSoonButton,
              style: const TextStyle(
                  color: AppColors.azulPrimario, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    if (flags != null && !flags.gamesEnabled) {
      return FeatureDisabledScreen(
        title: context.l10n.gamesMaintenanceTitle,
        subtitle: context.l10n.gamesMaintenanceSubtitle,
        icon: Icons.sports_esports_rounded,
        theme: FeatureTheme.games,
      );
    }

    final appConfig = ref.watch(appConfigProvider).valueOrNull;
    final adjoeReady = appConfig?.adjoeReady ?? false;

    return FadeTransition(
      opacity: _entranceAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_entranceAnim),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Hero header ──────────────────────────────────────────
              _HeroHeader(adjoeReady: adjoeReady),

              const SizedBox(height: 24),

              // ── Stats ────────────────────────────────────────────────
              _StatsRow(adjoeReady: adjoeReady),

              const SizedBox(height: 24),

              // ── Título carousel ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.sports_esports_rounded,
                        color: AppColors.colorJuegos, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.gamesPopularTitle,
                      style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openOfferwall,
                      child: Row(
                        children: [
                          Text(
                            context.l10n.gamesSeeAll,
                            style: const TextStyle(
                              color: AppColors.colorJuegos,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.colorJuegos, size: 11),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Carousel PageView ────────────────────────────────────
              SizedBox(
                height: 148,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _popularGames.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) {
                    final isActive = i == _currentPage;
                    return AnimatedBuilder(
                      animation: _pageCtrl,
                      builder: (context, child) {
                        double page = _currentPage.toDouble();
                        try {
                          page = _pageCtrl.page ?? _currentPage.toDouble();
                        } catch (_) {}
                        final diff = (page - i).abs();
                        final scale = (1.0 - diff * 0.07).clamp(0.88, 1.0);
                        final opacity = (1.0 - diff * 0.30).clamp(0.55, 1.0);
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(opacity: opacity, child: child),
                        );
                      },
                      child: _GameCard(
                        game: _popularGames[i],
                        isActive: isActive,
                        onTap: _openOfferwall,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ── Indicadores de página ────────────────────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_popularGames.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.colorJuegos
                            : AppColors.colorJuegos.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // ── Botón CTA animado ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AnimatedCTAButton(
                  loading: _loading,
                  adjoeReady: adjoeReady,
                  pulseAnim: _pulseAnim,
                  shimmerAnim: _shimmerAnim,
                  onTap: _openOfferwall,
                ),
              ),

              const SizedBox(height: 28),

              // ── Cómo funciona ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.gamesHowTitle,
                      style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HowItWorksCard(
                      step: '1',
                      icon: Icons.download_rounded,
                      title: context.l10n.gamesStep1Title,
                      desc: context.l10n.gamesStep1Desc,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 10),
                    _HowItWorksCard(
                      step: '2',
                      icon: Icons.sports_esports_rounded,
                      title: context.l10n.gamesStep2Title,
                      desc: context.l10n.gamesStep2Desc,
                      color: const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(height: 10),
                    _HowItWorksCard(
                      step: '3',
                      icon: Icons.monetization_on_rounded,
                      title: context.l10n.gamesStep3Title,
                      desc: context.l10n.gamesStep3Desc,
                      color: AppColors.verdePrimario,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Banner inferior ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.fondoElevado,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.fondoCardBorde),
                  ),
                  child: Row(children: [
                    Icon(
                      adjoeReady
                          ? Icons.check_circle_outline_rounded
                          : Icons.notifications_outlined,
                      color: AppColors.azulPrimario,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        adjoeReady
                            ? context.l10n.gamesOpenCatalog
                            : context.l10n.gamesComingNotify,
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final bool adjoeReady;
  const _HeroHeader({required this.adjoeReady});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30, right: -20,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -10,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: adjoeReady
                                        ? AppColors.verdePrimario
                                        : AppColors.dorado,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  adjoeReady
                                      ? context.l10n.gamesStatusActive
                                      : context.l10n.gamesStatusSoon,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on_rounded,
                                    color: Color(0xFFFFD700), size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.gamesHeroFreeLabel,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.gamesHeroTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.gamesHeroSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              context.l10n.gamesDailyLimit,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 60, height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final bool adjoeReady;
  const _StatsRow({required this.adjoeReady});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.videogame_asset_rounded,
            label: context.l10n.gamesStatGames,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.monetization_on_rounded,
            label: context.l10n.gamesStatReward,
            color: AppColors.azulPrimario,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.bolt_rounded,
            label: context.l10n.gamesStatInstant,
            color: AppColors.verdePrimario,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de juego (carousel) ───────────────────────────────────────
class _GameCard extends StatefulWidget {
  final _GameData game;
  final VoidCallback onTap;
  final bool isActive;
  const _GameCard(
      {required this.game, required this.onTap, this.isActive = false});

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  String _badgeLabel(_BadgeType type, BuildContext context) {
    switch (type) {
      case _BadgeType.popular:
        return context.l10n.gamesBadgePopular;
      case _BadgeType.vip:
        return context.l10n.gamesBadgeVip;
      case _BadgeType.top:
        return context.l10n.gamesBadgeTop;
    }
  }

  IconData _badgeIcon(_BadgeType type) {
    switch (type) {
      case _BadgeType.popular:
        return Icons.local_fire_department_rounded;
      case _BadgeType.vip:
        return Icons.diamond_rounded;
      case _BadgeType.top:
        return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(
                    alpha: widget.isActive ? 0.55 : 0.28),
                blurRadius: widget.isActive ? 20 : 10,
                spreadRadius: widget.isActive ? 2 : 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                // Imagen izquierda
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          CachedNetworkImage(
                            imageUrl: game.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Center(
                              child: Icon(game.fallbackIcon,
                                  color: Colors.white, size: 36),
                            ),
                            placeholder: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Info derecha
                Expanded(
                  flex: 1,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -18, right: -18,
                        child: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -14, left: -10,
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (game.badge != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_badgeIcon(game.badge!),
                                          color: Colors.white, size: 9),
                                      const SizedBox(width: 3),
                                      Text(
                                        _badgeLabel(game.badge!, context),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                game.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                game.category,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.monetization_on_rounded,
                                        color: Color(0xFFFFD700), size: 11),
                                    const SizedBox(width: 3),
                                    Text(
                                      '+${game.maxCoins.formatted}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botón CTA animado ─────────────────────────────────────────────────
class _AnimatedCTAButton extends StatelessWidget {
  final bool loading;
  final bool adjoeReady;
  final Animation<double> pulseAnim;
  final Animation<double> shimmerAnim;
  final VoidCallback onTap;

  const _AnimatedCTAButton({
    required this.loading,
    required this.adjoeReady,
    required this.pulseAnim,
    required this.shimmerAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xFF3B82F6);

    return AnimatedBuilder(
      animation: Listenable.merge([pulseAnim, shimmerAnim]),
      builder: (context, _) {
        final glow = pulseAnim.value;
        final shimmerX = shimmerAnim.value;

        return GestureDetector(
          onTap: loading ? null : onTap,
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.30 + glow * 0.30),
                        blurRadius: 12 + glow * 20,
                        spreadRadius: glow * 4,
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1D4ED8),
                          Color(0xFF2563EB),
                          Color(0xFF3B82F6),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(shimmerX * 250, 0),
                          child: Transform.rotate(
                            angle: math.pi / 6,
                            child: Container(
                              width: 60,
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.18),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (loading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sports_esports_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                adjoeReady
                                    ? context.l10n.gamesOpenButton
                                    : context.l10n.gamesExploreSoon,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  context.l10n.gamesFreeLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Cómo funciona ─────────────────────────────────────────────────────
class _HowItWorksCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _HowItWorksCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.05),
            AppColors.fondoElevado,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 46,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        step,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      title,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                      color: AppColors.textoSecundario,
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
