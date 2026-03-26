import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/tutorial/screens/tutorial_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/wallet/screens/cashout_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class AppRoutes {
  static const String splash      = '/';
  static const String onboarding  = '/onboarding';
  static const String tutorial    = '/tutorial';
  static const String home        = '/home';
  static const String cashout     = '/home/cashout';
  static const String profile     = '/profile';
}

// Escucha cambios de auth de Supabase y notifica al GoRouter
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthChangeNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _AuthChangeNotifier();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _authNotifier, // ← re-evalúa redirect cuando cambia auth
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth  = session != null;
      final loc     = state.matchedLocation;

      // Rutas que no redirigen
      if (loc == AppRoutes.splash   ||
          loc == AppRoutes.onboarding ||
          loc == AppRoutes.tutorial) return null;

      if (!isAuth) return AppRoutes.onboarding;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (_, __) => const TutorialScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'cashout',
            builder: (_, __) => const CashoutScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});
