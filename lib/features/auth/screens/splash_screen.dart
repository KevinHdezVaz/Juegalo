import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/version_check_service.dart';
import '../../../shared/providers/user_provider.dart';
import '../../tutorial/screens/tutorial_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;

      debugPrint('🚀 [Splash] Verificando actualización...');

      // Verificar si hay actualización forzada
      final needsUpdate =
          await VersionCheckService.instance.checkAndPromptUpdate(context);
      if (needsUpdate) return;
      if (!mounted) return;

      debugPrint('🚀 [Splash] Revisando notificación inicial...');

      // Verificar si la app fue abierta desde una notificación (app cerrada)
      await NotificationService.instance.checkInitialMessage();

      if (!mounted) return;

      debugPrint('🚀 [Splash] Leyendo sesión...');

      // Escuchar navegación por notificación (solo si hay sesión activa)
      final session = ref.read(currentSessionProvider);
      if (session != null) {
        _notifSub = NotificationService.instance.onNavigate.listen((route) {
          if (mounted) context.go(route);
        });
      }

      debugPrint('🚀 [Splash] Verificando tutorial...');

      // Primera vez: mostrar tutorial antes del login
      final tutorialDone = await isTutorialCompleted();
      if (!mounted) return;

      debugPrint('🚀 [Splash] tutorialDone=$tutorialDone, session=${session != null}');

      if (!tutorialDone) {
        context.go(AppRoutes.tutorial);
        return;
      }

      // Tutorial ya visto: ir al home (si hay sesión) o al login
      context.go(session != null ? AppRoutes.home : AppRoutes.onboarding);
    } catch (e, st) {
      // Nunca quedarse atascado en el splash — fallback garantizado
      debugPrint('❌ [Splash] Error en _navigate: $e\n$st');
      if (!mounted) return;
      try {
        final session = Supabase.instance.client.auth.currentSession;
        context.go(session != null ? AppRoutes.home : AppRoutes.onboarding);
      } catch (_) {
        context.go(AppRoutes.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.azulPrimario.withValues(alpha: 0.40),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 110, height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: AppColors.textoPrimario,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.appTagline.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.azulPrimario,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.azulPrimario,
                    strokeWidth: 2.5,
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
