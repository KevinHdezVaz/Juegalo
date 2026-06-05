import 'dart:io';
import 'dart:ui';
import 'package:adjoe/sdk.dart' show Playtime;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:juegalo_gana_dinero/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/feature_flags_provider.dart';
import 'shared/widgets/maintenance_screen.dart';
import 'core/services/notification_service.dart';
import 'core/services/version_check_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Analytics
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Crashlytics — captura errores globales
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Notificaciones push
  await NotificationService.instance.init();

  // Remote Config (force update)
  await VersionCheckService.instance.init();

  // App Tracking Transparency (iOS 14+)
  // Debe pedirse ANTES de inicializar AdMob para que Google pueda
  // usar el IDFA si el usuario lo autoriza.
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      // Pequeña pausa para que el diálogo ATT aparezca después de que
      // la app esté completamente visible (recomendado por Apple).
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  // AdMob
  await MobileAds.instance.initialize();

  // Adjoe Playtime Offerwall — inicializar SDK al arranque
  // El userId se pasa luego al abrir el catálogo (games_screen)
  if (Platform.isAndroid) {
    try {
      await Playtime.init(AppConstants.adjoeAppId, null);
      debugPrint('✅ [Adjoe] SDK inicializado');
    } catch (e) {
      debugPrint('🟡 [Adjoe] Error al inicializar: $e');
    }
  }

  // ── Dispositivos de prueba (no cuentan como tráfico inválido) ────
  // Corre la app y busca en los logs: "Use RequestConfiguration.Builder
  // .setTestDeviceIds" — ahí aparece tu device ID. Pégalo aquí.
  // Puedes agregar varios IDs si pruebas en más de un dispositivo.
  //
  // ⚠️ NUNCA quites los test devices y luego veas/clickees tus propios
  // ads — Google lo detecta como tráfico inválido y puede suspenderte
  // la cuenta de AdMob. En release siempre debe ir activo para tu cel.
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: [
        '9AC32436E06290FF358D760DFEB15FAB', // Kevin - Android
      ],
    ),
  );

  // Orientación solo portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Fechas en español
  await initializeDateFormatting('es');

  // Si ya hay sesión activa, refrescar el FCM token en la BD.
  // requestAndSaveToken solo se llama al hacer login — si el usuario ya
  // tenía sesión, el token guardado puede ser de otro dispositivo o estar vencido.
  final existingSession = Supabase.instance.client.auth.currentSession;
  if (existingSession != null) {
    NotificationService.instance.requestAndSaveToken().catchError((_) {});
  }

  runApp(const ProviderScope(child: JuegaloApp()));
}

class JuegaloApp extends ConsumerWidget {
  const JuegaloApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router     = ref.watch(appRouterProvider);
    final locale     = ref.watch(localeProvider);
    final flagsAsync = ref.watch(featureFlagsProvider);

    // Mientras se cargan los flags mostramos la app normalmente.
    // Si hay error de red, featureFlagsProvider devuelve defaults seguros (no lanza).
    final inMaintenance = flagsAsync.valueOrNull?.maintenanceMode ?? false;

    // MaterialApp base — se usa en ambos modos para tener localizaciones y tema.
    if (inMaintenance) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es'),
          Locale('en'),
          Locale('pt'),
        ],
        home: const MaintenanceScreen(),
      );
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('pt'),
      ],
    );
  }
}
