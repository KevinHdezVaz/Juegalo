import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

// ── Tapjoy / Adjoe config ─────────────────────────────────────────
// TODO: reemplazar con tu API key de publishers.tapjoy.com
const _tapjoyReady = AppConstants.tapjoyApiKey != 'TAPJOY_API_KEY';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool _loading = true;

  // URL del offerwall de Tapjoy (WebView offerwall)
  String get _offerwallUrl {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    return 'https://offerwall.tapjoy.com/v2/sdk?'
        'sdk_type=tapjoy_sdk'
        '&app_id=${AppConstants.tapjoyApiKey}'
        '&user_id=$uid'
        '&display_multiplier=1';
  }

  @override
  Widget build(BuildContext context) {
    if (!_tapjoyReady) return const _SetupPlaceholder();

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_offerwallUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useWideViewPort: true,
            loadWithOverviewMode: true,
            domStorageEnabled: true,
          ),
          onLoadStop: (_, __) => setState(() => _loading = false),
          onLoadStart: (_, __) => setState(() => _loading = true),
        ),
        if (_loading)
          Container(
            color: AppColors.fondoPrincipal,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.colorJuegos),
            ),
          ),
      ],
    );
  }
}

// ── Placeholder cuando no hay credenciales Tapjoy ────────────────
class _SetupPlaceholder extends StatelessWidget {
  const _SetupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Ícono principal
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.colorJuegos.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.sports_esports_rounded,
                size: 42, color: AppColors.colorJuegos),
          ),
          const SizedBox(height: 20),

          const Text('Juegos Tapjoy',
              style: TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Miles de juegos y apps que pagan cuando tus usuarios los instalan y completan misiones.',
            style: TextStyle(
                color: AppColors.textoSecundario, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Métricas
          Row(children: [
            _MetricCard(
              icon: Icons.videogame_asset_rounded,
              value: '10,000+',
              label: 'Juegos disponibles',
              color: AppColors.colorJuegos,
            ),
            const SizedBox(width: 10),
            _MetricCard(
              icon: Icons.attach_money_rounded,
              value: '\$1–\$5',
              label: 'Por instalación',
              color: AppColors.verdePrimario,
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _MetricCard(
              icon: Icons.public_rounded,
              value: 'Global',
              label: 'LatAm + USA',
              color: AppColors.dorado,
            ),
            const SizedBox(width: 10),
            _MetricCard(
              icon: Icons.trending_up_rounded,
              value: '60%',
              label: 'Para el usuario',
              color: AppColors.colorEncuestas,
            ),
          ]),

          const SizedBox(height: 28),

          // Pasos
          _StepCard(step: '1', title: 'Regístrate en Tapjoy',
              description: 'publishers.tapjoy.com → Create Publisher Account',
              color: AppColors.colorJuegos),
          const SizedBox(height: 10),
          _StepCard(step: '2', title: 'Crea una app',
              description: 'Agrega JUÉGALO (Android) y obtén tu API Key',
              color: AppColors.colorJuegos),
          const SizedBox(height: 10),
          _StepCard(step: '3', title: 'Configura postbacks',
              description: 'URL: \${apiBaseUrl}/api/postback/tapjoy',
              color: AppColors.colorJuegos),
          const SizedBox(height: 10),
          _StepCard(step: '4', title: 'Activa los juegos',
              description: 'Pon tu API Key en app_constants.dart → tapjoyApiKey',
              color: AppColors.colorJuegos),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.colorJuegos.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.colorJuegos.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.dorado, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tapjoy ya tiene miles de publishers. No necesitas reclutar juegos — te conectas y ya tienes el catálogo completo desde el día 1.',
                    style: TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 13, height: 1.4),
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

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _MetricCard({
    required this.icon, required this.value,
    required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.fondoElevado,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.fondoCardBorde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textoSecundario, fontSize: 11)),
            ],
          ),
        ),
      );
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final Color color;
  const _StepCard({
    required this.step, required this.title,
    required this.description, required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fondoElevado,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fondoCardBorde),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Center(
                child: Text(step,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: const TextStyle(
                          color: AppColors.textoSecundario, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}
