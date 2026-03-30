import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

// ── Configuración de redes ────────────────────────────────────────
// Llena la que tengas primero. La app usa la primera que esté lista.

const _adjoeAppId = AppConstants.adjoeAppId; // adjoe.io
const _tapjoyApiKey = AppConstants.tapjoyApiKey; // publishers.tapjoy.com

// Red activa (cambia cuando tengas credenciales)
const _activeNetwork = _OfferwallNetwork.none; // .adjoe | .tapjoy | .none

enum _OfferwallNetwork { adjoe, tapjoy, none }

// ── URL del offerwall según red ───────────────────────────────────
String _offerwallUrl(String uid) => switch (_activeNetwork) {
      _OfferwallNetwork.adjoe => 'https://sdk.adjoe.io/offerwall/'
          '?app_id=$_adjoeAppId'
          '&user_id=$uid'
          '&ua_network=organic',
      _OfferwallNetwork.tapjoy => 'https://offerwall.tapjoy.com/v2/sdk'
          '?sdk_type=tapjoy_sdk'
          '&app_id=$_tapjoyApiKey'
          '&user_id=$uid',
      _OfferwallNetwork.none => '',
    };

// ── Pantalla principal ────────────────────────────────────────────
class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    if (_activeNetwork == _OfferwallNetwork.none) {
      return const _OfferwallPlaceholder();
    }

    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    final url = _offerwallUrl(uid);

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useWideViewPort: true,
            loadWithOverviewMode: true,
            domStorageEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          onLoadStop: (_, __) => setState(() => _loading = false),
          onLoadStart: (_, __) => setState(() => _loading = true),
        ),
        if (_loading)
          Container(
            color: AppColors.fondoPrincipal,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.colorJuegos),
                  SizedBox(height: 16),
                  Text('Cargando juegos…',
                      style: TextStyle(color: AppColors.textoSecundario)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Placeholder: aún sin red configurada ─────────────────────────
class _OfferwallPlaceholder extends StatelessWidget {
  const _OfferwallPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Hero
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF5B21B6),
                  Color(0xFF7C3AED),
                  Color(0xFF8B5CF6)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.colorJuegos.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.sports_esports_rounded,
                size: 46, color: Colors.white),
          ),
          const SizedBox(height: 18),
          const Text('Juegos & Ofertas',
              style: TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Instala juegos, completa misiones\ny gana monedas reales.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textoSecundario, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          // ── Cómo funciona ─────────────────────────────────────
          _SectionTitle('¿Cómo funciona?'),
          const SizedBox(height: 12),
          _HowItWorksRow(
            icon: Icons.download_rounded,
            title: 'Instala un juego',
            subtitle: 'Elige de miles de juegos disponibles',
            color: AppColors.colorJuegos,
          ),
          const SizedBox(height: 8),
          _HowItWorksRow(
            icon: Icons.emoji_events_rounded,
            title: 'Completa misiones',
            subtitle: 'Llega al nivel X, juega Y minutos…',
            color: AppColors.dorado,
          ),
          const SizedBox(height: 8),
          _HowItWorksRow(
            icon: Icons.monetization_on_rounded,
            title: 'Gana monedas',
            subtitle: '\$1–\$5 USD por instalación completada',
            color: AppColors.verdePrimario,
          ),
          const SizedBox(height: 24),

          // ── Redes disponibles ─────────────────────────────────
          _SectionTitle('Redes de ofertas'),
          const SizedBox(height: 12),
          _NetworkCard(
            name: 'Adjoe',
            description:
                'Recompensas por tiempo jugado. El modelo de JustPlay. Ideal para LatAm y USA.',
            badge: 'RECOMENDADO',
            badgeColor: AppColors.verdePrimario,
            icon: Icons.timer_rounded,
            color: const Color(0xFF6C5CE7),
            steps: const [
              'Regístrate en adjoe.io → Publishers',
              'Crea una app con tu bundle ID',
              'Obtén tu App ID',
              'Ponlo en app_constants.dart → adjoeAppId',
            ],
            url: 'https://adjoe.io',
          ),
          const SizedBox(height: 12),
          _NetworkCard(
            name: 'Tapjoy / Liftoff',
            description:
                'El offerwall más grande. +10,000 juegos globales. Requiere app publicada en Play Store.',
            badge: 'REQUIERE APP PUBLICADA',
            badgeColor: AppColors.textoSecundario,
            icon: Icons.videogame_asset_rounded,
            color: AppColors.colorJuegos,
            steps: const [
              'Publica JUEGALO en Play Store (beta)',
              'Regístrate en publishers.tapjoy.com',
              'Crea tu app y obtén el API Key',
              'Ponlo en app_constants.dart → tapjoyApiKey',
            ],
            url: 'https://tapjoy.com',
          ),
          const SizedBox(height: 24),

          // ── Activa cuando tengas credenciales ─────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.colorJuegos.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.colorJuegos.withValues(alpha: 0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.code_rounded, color: AppColors.dorado, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cuando tengas tu App ID, cambia _activeNetwork a '
                    '_OfferwallNetwork.adjoe (o .tapjoy) en games_screen.dart '
                    'y los juegos aparecerán automáticamente.',
                    style: TextStyle(
                        color: AppColors.textoPrimario,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textoPrimario,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      );
}

class _HowItWorksRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _HowItWorksRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fondoElevado,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fondoCardBorde),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textoPrimario,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textoSecundario, fontSize: 12)),
              ],
            ),
          ),
        ]),
      );
}

class _NetworkCard extends StatelessWidget {
  final String name;
  final String description;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final Color color;
  final List<String> steps;
  final String url;

  const _NetworkCard({
    required this.name,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.color,
    required this.steps,
    required this.url,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fondoElevado,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(name,
                  style: const TextStyle(
                      color: AppColors.textoPrimario,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge,
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(description,
                style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 12,
                    height: 1.4)),
            const SizedBox(height: 12),
            // Pasos
            ...steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: Text('Ir a $name',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      );
}
