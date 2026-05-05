import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/l10n_ext.dart';

const _kTutorialKey = 'tutorial_completed';

Future<bool> isTutorialCompleted() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(_kTutorialKey) ?? false;
}

Future<void> markTutorialCompleted() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(_kTutorialKey, true);
}

// ── Modelo de slide ───────────────────────────────────────────────
class _SlideData {
  final List<Color> gradient;
  final String emoji;
  final String title;
  final String subtitle;
  final List<_Item> items;
  final bool showLogo;

  const _SlideData({
    required this.gradient,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.items = const [],
    this.showLogo = false,
  });
}

class _Item {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _Item({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });
}

// ── Pantalla principal ────────────────────────────────────────────
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
    final slides = _buildSlides(context);
    if (_current < slides.length - 1) {
      _controller.animateToPage(page: _current + 1);
    } else {
      _finish();
    }
  }

  List<_SlideData> _buildSlides(BuildContext context) {
    final l = context.l10n;
    return [
      _SlideData(
        gradient: const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF283593)],
        emoji: '🎮',
        title: l.tutorialWelcomeTitle,
        subtitle: l.tutorialWelcomeSubtitle,
        showLogo: true,
        items: [
          _Item(
              emoji: '✅',
              label: l.tutorialWelcomeFree,
              value: l.tutorialWelcomeFreeValue,
              color: const Color(0xFFBBF7D0)),
          _Item(
              emoji: '🌎',
              label: l.tutorialWelcomeLatam,
              value: l.tutorialWelcomeLatamValue,
              color: const Color(0xFF93C5FD)),
          _Item(
              emoji: '⚡',
              label: l.tutorialWelcomeStart,
              value: l.tutorialWelcomeStartValue,
              color: const Color(0xFFFDE68A)),
        ],
      ),
      _SlideData(
        gradient: const [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1A5C38)],
        emoji: '🪙',
        title: l.tutorialEarnTitle,
        subtitle: l.tutorialEarnSubtitle,
        items: [
          _Item(
              emoji: '📹',
              label: l.tutorialEarnVideos,
              value: l.tutorialEarnVideosValue,
              color: const Color(0xFFFCA5A5)),
          _Item(
              emoji: '📋',
              label: l.tutorialEarnSurveys,
              value: l.tutorialEarnSurveysValue,
              color: const Color(0xFFC4B5FD)),
          _Item(
              emoji: '🕹️',
              label: l.tutorialEarnGames,
              value: l.tutorialEarnGamesValue,
              color: const Color(0xFF93C5FD)),
        ],
      ),
      _SlideData(
        gradient: const [Color(0xFF78350F), Color(0xFFB45309), Color(0xFF92400E)],
        emoji: '🏆',
        title: l.tutorialRankingTitle,
        subtitle: l.tutorialRankingSubtitle,
        items: [
          _Item(
              emoji: '🥇',
              label: l.tutorialRankingFirst,
              value: l.tutorialRankingFirstValue,
              color: const Color(0xFFFDE68A)),
          _Item(
              emoji: '🥈',
              label: l.tutorialRankingSecond,
              value: l.tutorialRankingSecondValue,
              color: const Color(0xFFE5E7EB)),
          _Item(
              emoji: '🥉',
              label: l.tutorialRankingThird,
              value: l.tutorialRankingThirdValue,
              color: const Color(0xFFFED7AA)),
        ],
      ),
      _SlideData(
        gradient: const [Color(0xFF0A0E1A), Color(0xFF0F172A), Color(0xFF1E1B4B)],
        emoji: '💸',
        title: l.tutorialCashoutTitle,
        subtitle: l.tutorialCashoutSubtitle,
        items: [
          _Item(
              emoji: '💳',
              label: 'PayPal',
              value: l.tutorialCashoutPaypalValue,
              color: const Color(0xFF93C5FD)),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides(context);
    final isLast = _current == slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // ── LiquidSwipe ──────────────────────────────────────────
          LiquidSwipe(
            liquidController: _controller,
            enableSideReveal: _current < slides.length - 1,
            disableUserGesture: false,
            slideIconWidget: _current == slides.length - 1
                ? const SizedBox.shrink()
                : const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white54, size: 18),
            positionSlideIcon: 0.54,
            waveType: WaveType.liquidReveal,
            onPageChangeCallback: (page) {
              if (_current == slides.length - 1 && page == 0) {
                Future.delayed(Duration.zero, () {
                  _controller.animateToPage(
                      page: slides.length - 1, duration: 300);
                });
                return;
              }
              setState(() => _current = page);
            },
            pages: [
              ...slides.asMap().entries.map(
                    (e) =>
                        _SlidePage(slide: e.value, isActive: _current == e.key),
                  ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: slides.last.gradient,
                  ),
                ),
              ),
            ],
          ),

          // ── Botón Saltar ─────────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isLast ? 0 : 1,
                  child: TextButton(
                    onPressed: isLast ? null : _finish,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                    ),
                    child: Text(
                      context.l10n.tutorialSkip,
                      style:
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Dots + Botones (abajo) ───────────────────────────────
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
                    _DotsIndicator(count: slides.length, current: _current),
                    const SizedBox(height: 20),
                    if (isLast)
                      Row(
                        children: [
                          SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () => _controller.animateToPage(
                                page: _current - 1,
                                duration: 600,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                    color:
                                        Colors.white.withValues(alpha: 0.50)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                              ),
                              child: const Icon(Icons.arrow_back_ios_rounded,
                                  size: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFF8C00)
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _finish,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.l10n.tutorialStartEarning,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.l10n.tutorialNext,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
                            ),
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

// ── Página de slide con animaciones ──────────────────────────────
class _SlidePage extends StatefulWidget {
  final _SlideData slide;
  final bool isActive;
  const _SlidePage({required this.slide, required this.isActive});

  @override
  State<_SlidePage> createState() => _SlidePageState();
}

class _SlidePageState extends State<_SlidePage> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;

  // Entry animations
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final List<Animation<double>> _itemFades;
  late final List<Animation<Offset>> _itemSlides;

  // Float animation
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Icon: elastic bounce in
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Title
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );

    // Subtitle
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.72, curve: Curves.easeOut),
      ),
    );

    // Items stagger
    _itemFades = List.generate(3, (i) {
      final start = 0.58 + i * 0.08;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, (start + 0.18).clamp(0, 1),
              curve: Curves.easeOut),
        ),
      );
    });
    _itemSlides = List.generate(3, (i) {
      final start = 0.58 + i * 0.08;
      return Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
          .animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, (start + 0.18).clamp(0, 1),
              curve: Curves.easeOutCubic),
        ),
      );
    });

    // Float
    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    if (widget.isActive) _startEntry();
  }

  void _startEntry() {
    _entryCtrl.reset();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(_SlidePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startEntry();
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradient,
        ),
      ),
      child: Stack(
        children: [
          // ── Círculos decorativos de fondo ──────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _DecorCircle(size: 260, opacity: 0.07),
          ),
          Positioned(
            bottom: 160,
            left: -80,
            child: _DecorCircle(size: 220, opacity: 0.06),
          ),
          Positioned(
            top: 200,
            right: -40,
            child: _DecorCircle(size: 140, opacity: 0.05),
          ),
          Positioned(
            bottom: 80,
            right: 30,
            child: _DecorCircle(size: 80, opacity: 0.08),
          ),

          // ── Contenido ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 180),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícono principal (animado)
                  AnimatedBuilder(
                    animation: Listenable.merge([_entryCtrl, _floatCtrl]),
                    builder: (context, _) {
                      return Transform.translate(
                        offset: Offset(0, _floatY.value),
                        child: FadeTransition(
                          opacity: _iconOpacity,
                          child: ScaleTransition(
                            scale: _iconScale,
                            child: slide.showLogo
                                ? Container(
                                    width: 118,
                                    height: 118,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.35),
                                          blurRadius: 28,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: Image.asset(
                                        'assets/icons/app_icon.png',
                                        width: 118,
                                        height: 118,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 118,
                                    height: 118,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: slide.emoji == '🪙'
                                          ? const Icon(Icons.monetization_on, color: Colors.amber, size: 54)
                                          : Text(
                                              slide.emoji,
                                              style: const TextStyle(fontSize: 54),
                                            ),
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Título
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtítulo
                  SlideTransition(
                    position: _subtitleSlide,
                    child: FadeTransition(
                      opacity: _subtitleFade,
                      child: Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  // Items
                  if (slide.items.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ...slide.items.asMap().entries.map((e) {
                      final idx = e.key.clamp(0, 2);
                      return SlideTransition(
                        position: _itemSlides[idx],
                        child: FadeTransition(
                          opacity: _itemFades[idx],
                          child: _ItemCard(item: e.value),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Círculo decorativo ────────────────────────────────────────────
class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

// ── Tarjeta de ítem ───────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final _Item item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji en círculo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withValues(alpha: 0.18),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          // Label
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
          // Value badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: item.color.withValues(alpha: 0.35)),
            ),
            child: Text(
              item.value,
              style: TextStyle(
                color: item.color,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Indicadores de puntos ─────────────────────────────────────────
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(4),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 6,
                    )
                  ]
                : [],
          ),
        );
      }),
    );
  }
}
