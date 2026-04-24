import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_router.dart';

const _kTutorialKey = 'tutorial_completed';

Future<bool> isTutorialCompleted() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(_kTutorialKey) ?? false;
}

Future<void> markTutorialCompleted() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(_kTutorialKey, true);
}

// ── Datos de cada slide ────────────────────────────────────────────
class _SlideData {
  final Color bgColor;
  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_Item> items;

  const _SlideData({
    required this.bgColor,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.items = const [],
  });
}

class _Item {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Item({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

final _slides = [
  _SlideData(
    bgColor: const Color(0xFF1D4ED8),
    accentColor: Colors.white,
    icon: Icons.sports_esports_rounded,
    title: '¡Bienvenido a JUEGALO!',
    subtitle: 'La app donde juegas, haces\nencuestas y ganas dinero real.',
    items: const [
      _Item(
          icon: Icons.check_circle_rounded,
          label: '100% gratis para siempre',
          value: 'Sin cargos',
          color: Color(0xFFBBF7D0)),
      _Item(
          icon: Icons.language_rounded,
          label: 'Disponible en Latinoamérica',
          value: 'Desde hoy',
          color: Color(0xFF93C5FD)),
      _Item(
          icon: Icons.bolt_rounded,
          label: 'Empieza a ganar en 1 minuto',
          value: 'Rápido',
          color: Color(0xFFFDE68A)),
    ],
  ),
  _SlideData(
    bgColor: const Color(0xFF15803D),
    accentColor: Colors.white,
    icon: Icons.monetization_on_rounded,
    title: 'Gana monedas fácil',
    subtitle: 'Tres formas de acumular\nmonedas cada día.',
    items: const [
      _Item(
          icon: Icons.play_circle_rounded,
          label: 'Videos',
          value: '+50 monedas c/u',
          color: Color(0xFFFCA5A5)),
      _Item(
          icon: Icons.assignment_rounded,
          label: 'Encuestas',
          value: 'hasta 6,000 monedas',
          color: Color(0xFFC4B5FD)),
      _Item(
          icon: Icons.videogame_asset_rounded,
          label: 'Juegos',
          value: 'hasta 2,000 monedas',
          color: Color(0xFF93C5FD)),
    ],
  ),
  _SlideData(
    bgColor: const Color(0xFFB45309),
    accentColor: Colors.white,
    icon: Icons.emoji_events_rounded,
    title: 'Ranking semanal',
    subtitle: 'Compite cada semana.\nLos mejores ganan premios extra.',
    items: const [
      _Item(
          icon: Icons.looks_one_rounded,
          label: 'Puesto #1',
          value: '5,000 monedas',
          color: Color(0xFFFDE68A)),
      _Item(
          icon: Icons.looks_two_rounded,
          label: 'Puesto #2',
          value: '2,000 monedas',
          color: Color(0xFFE5E7EB)),
      _Item(
          icon: Icons.looks_3_rounded,
          label: 'Puesto #3',
          value: '1,000 monedas',
          color: Color(0xFFFED7AA)),
    ],
  ),
  _SlideData(
    bgColor: const Color(0xFF0F172A),
    accentColor: Colors.white,
    icon: Icons.account_balance_wallet_rounded,
    title: 'Cobra cuando quieras',
    subtitle: '10,000 monedas = \$1.00 USD.\nRetira desde \$1 sin comisión.',
    items: const [
      _Item(
          icon: Icons.credit_card_rounded,
          label: 'PayPal',
          value: 'Instantáneo',
          color: Color(0xFF93C5FD)),
      _Item(
          icon: Icons.phone_android_rounded,
          label: 'MercadoPago',
          value: 'En minutos',
          color: Color(0xFF6EE7B7)),
      _Item(
          icon: Icons.store_rounded,
          label: 'OXXO / Tienda',
          value: 'Efectivo',
          color: Color(0xFFFCA5A5)),
    ],
  ),
];

// ── Pantalla ──────────────────────────────────────────────────────
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = LiquidController();
  int _current = 0;

  Future<void> _finish() async {
    await markTutorialCompleted();
    if (mounted) context.go(AppRoutes.onboarding);
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _controller.animateToPage(page: _current + 1);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // ── LiquidSwipe ──────────────────────────────────────
          LiquidSwipe(
            liquidController: _controller,
            enableSideReveal: _current < _slides.length - 1,
            disableUserGesture: false,
            slideIconWidget: _current == _slides.length - 1
                ? const SizedBox.shrink()
                : const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
            positionSlideIcon: 0.54,
            waveType: WaveType.liquidReveal,
            onPageChangeCallback: (page) {
              // Si detecta que hizo loop desde el último slide, regresa
              if (_current == _slides.length - 1 && page == 0) {
                Future.delayed(Duration.zero, () {
                  _controller.animateToPage(
                    page: _slides.length - 1,
                    duration: 300,
                  );
                });
                return;
              }
              setState(() => _current = page);
            },
            pages: [
              ..._slides.map((s) => _SlidePage(slide: s)),
              // Página fantasma: mismo color que el último slide
              // → el "side reveal" muestra este color = invisible
              Container(color: _slides.last.bgColor),
            ],
          ),

          // (sin bloqueador — el usuario puede regresar)

          // ── Botón Saltar (arriba derecha) ────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: isLast
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                        ),
                        child: const Text('Saltar',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
              ),
            ),
          ),

          // ── Indicadores + Botón (abajo) ──────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots
                    _DotsIndicator(
                      count: _slides.length,
                      current: _current,
                    ),
                    const SizedBox(height: 20),
                    // Botones
                    if (isLast)
                      Row(
                        children: [
                          // ← Anterior
                          SizedBox(
                            height: 54,
                            child: OutlinedButton(
                              onPressed: () => _controller.animateToPage(
                                page: _current - 1,
                                duration: 600,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.50)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                              ),
                              child: const Icon(
                                  Icons.arrow_back_ios_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // ¡Empezar!
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _finish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _slides[_current].bgColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '¡Empezar a ganar!',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _slides[_current].bgColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Siguiente →',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Página individual (fondo de color) ───────────────────────────
class _SlidePage extends StatelessWidget {
  final _SlideData slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: slide.bgColor,
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 180),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícono
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(slide.icon, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 28),

          // Título
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),

          // Subtítulo
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 15,
              height: 1.6,
            ),
          ),

          // Items
          if (slide.items.isNotEmpty) ...[
            const SizedBox(height: 28),
            ...slide.items.map((item) => _ItemRow(item: item)),
          ],
        ],
      ),
    );
  }
}

// ── Fila de ítem ──────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final _Item item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 24, color: item.color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.value,
              style: TextStyle(
                color: item.color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Puntos indicadores ────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
