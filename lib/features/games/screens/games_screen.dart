import 'package:adjoe/sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/providers/feature_flags_provider.dart';
import '../../../shared/widgets/feature_disabled_screen.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool _loading = false;

  bool get _adjoeReady => AppConstants.adjoeAppId != 'ADJOE_APP_ID';

  Future<void> _openOfferwall() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    if (!_adjoeReady) {
      _showComingSoon();
      return;
    }

    setState(() => _loading = true);
    try {
      final options = PlaytimeOptions(
        userId: uid,
        sdkHash: AppConstants.adjoeAppId,
        params: PlaytimeParams(placement: 'games_tab'),
      );
      await Playtime.showCatalogWithOptions(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.gamesOpenError),
            backgroundColor: Colors.red,
          ),
        );
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
        title: Text(context.l10n.gamesComingSoonTitle,
            style: const TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.w700)),
        content: Text(
          context.l10n.gamesComingSoonContent,
          style: const TextStyle(color: AppColors.textoSecundario, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.gamesComingSoonButton,
                style: const TextStyle(color: AppColors.azulPrimario, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(featureFlagsProvider).valueOrNull;
    if (flags != null && !flags.gamesEnabled) {
      return const FeatureDisabledScreen(
        title: 'Juegos temporalmente desactivados',
        message: 'Estamos haciendo mejoras. Vuelve pronto.',
        icon: Icons.sports_esports_rounded,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.colorJuegos.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.sports_esports_rounded,
                size: 50, color: Colors.white),
          ),
          const SizedBox(height: 28),

          Text(
            context.l10n.gamesTitle,
            style: const TextStyle(
              color: AppColors.textoPrimario,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _adjoeReady
                  ? AppColors.colorJuegos.withValues(alpha: 0.15)
                  : AppColors.colorJuegos.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _adjoeReady
                    ? AppColors.colorJuegos
                    : AppColors.colorJuegos.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _adjoeReady ? context.l10n.gamesAvailable : context.l10n.gamesSoon,
              style: const TextStyle(
                color: AppColors.colorJuegos,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            context.l10n.gamesDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _openOfferwall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.colorJuegos,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _adjoeReady ? context.l10n.gamesOpenButton : context.l10n.gamesExploreSoon,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 32),

          _FeatureCard(
            icon: Icons.videogame_asset_rounded,
            title: context.l10n.gamesInstallGames,
            description: context.l10n.gamesInstallGamesDesc,
            color: const Color(0xFF7C3AED),
            available: _adjoeReady,
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.download_rounded,
            title: context.l10n.gamesDownloadApps,
            description: context.l10n.gamesDownloadAppsDesc,
            color: const Color(0xFF5B21B6),
            available: _adjoeReady,
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.star_rounded,
            title: context.l10n.gamesCompleteMissions,
            description: context.l10n.gamesCompleteMissionsDesc,
            color: const Color(0xFF4C1D95),
            available: _adjoeReady,
          ),
          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.fondoElevado,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.fondoCardBorde),
            ),
            child: Row(children: [
              Icon(
                _adjoeReady
                    ? Icons.check_circle_outline_rounded
                    : Icons.notifications_outlined,
                color: AppColors.azulPrimario,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _adjoeReady
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
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool available;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fondoElevado,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fondoCardBorde),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textoPrimario,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 3),
              Text(description,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
        Icon(
          available ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
          color: available ? AppColors.colorJuegos : AppColors.textoDeshabilitado,
          size: 18,
        ),
      ]),
    );
  }
}
