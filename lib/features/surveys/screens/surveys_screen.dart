import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

// ── CPX Research config ──────────────────────────────────────────
// TODO: reemplazar con tu App ID de cpx-research.com → Publishers
const _cpxAppId = '';
const _cpxReady = _cpxAppId != '';

class SurveysScreen extends ConsumerStatefulWidget {
  const SurveysScreen({super.key});

  @override
  ConsumerState<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends ConsumerState<SurveysScreen> {
  bool _loading = true;

  String get _surveyUrl {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    return 'https://offers.cpx-research.com/index.php'
        '?app_id=$_cpxAppId'
        '&ext_user_id=$uid'
        '&output_method=publisher_iframe';
  }

  @override
  Widget build(BuildContext context) {
    if (!_cpxReady) return const _SetupPlaceholder();

    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_surveyUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useWideViewPort: true,
            loadWithOverviewMode: true,
          ),
          onLoadStop: (_, __) => setState(() => _loading = false),
          onLoadStart: (_, __) => setState(() => _loading = true),
        ),
        if (_loading)
          Container(
            color: AppColors.fondoPrincipal,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.colorEncuestas),
            ),
          ),
      ],
    );
  }
}

// ── Placeholder cuando no hay credenciales CPX ───────────────────
class _SetupPlaceholder extends StatelessWidget {
  const _SetupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.colorEncuestas.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.assignment_outlined,
                size: 42, color: AppColors.colorEncuestas),
          ),
          const SizedBox(height: 20),
          const Text('Encuestas CPX Research',
              style: TextStyle(
                  color: AppColors.textoPrimario,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Completa encuestas y gana monedas. Siempre hay encuestas disponibles.',
            style: TextStyle(
                color: AppColors.textoSecundario, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _StepCard(step: '1', title: 'Regístrate en CPX Research',
              description: 'cpx-research.com → Publishers → Create Account',
              color: AppColors.colorEncuestas),
          const SizedBox(height: 10),
          _StepCard(step: '2', title: 'Crea una app publisher',
              description: 'Agrega JUÉGALO y obtén tu App ID',
              color: AppColors.colorEncuestas),
          const SizedBox(height: 10),
          _StepCard(step: '3', title: 'Activa las encuestas',
              description: 'Pon tu App ID en surveys_screen.dart → _cpxAppId',
              color: AppColors.colorEncuestas),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.colorEncuestas.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.colorEncuestas.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.monetization_on_rounded, color: AppColors.dorado, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'CPX paga \$0.50–\$5.00 por encuesta. 60% va al usuario, 40% a la app.',
                  style: TextStyle(
                      color: AppColors.textoPrimario, fontSize: 13, height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
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
