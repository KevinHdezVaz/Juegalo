import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';

// ── AdGem Offerwall ──────────────────────────────────────────────
const _adgemAppId = '32279';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  String get _playerId {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    return uid.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String get _offerwallUrl =>
      'https://adunits.adgem.com/wall?appid=$_adgemAppId&playerid=$_playerId';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.fondoPrincipal)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onWebResourceError: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(_offerwallUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (_playerId.isEmpty) {
      return const Center(
        child: Text('Inicia sesión para ver las ofertas',
            style: TextStyle(color: AppColors.textoSecundario)),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),

        if (_loading)
          Container(
            color: AppColors.fondoPrincipal,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.colorJuegos.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sports_esports_rounded,
                        size: 38, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  const Text('Cargando ofertas...',
                      style: TextStyle(
                          color: AppColors.textoPrimario,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Instala juegos y apps para ganar monedas',
                      style: TextStyle(
                          color: AppColors.textoSecundario, fontSize: 12)),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                        color: AppColors.colorJuegos, strokeWidth: 2.5),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
