class AppConstants {
  AppConstants._();

  // ── App info ──────────────────────────────────────────────────
  static const String appName = 'JUEGALO';
  static const String appTagline = 'Gana Dinero Real';

  // ── Sistema de monedas ────────────────────────────────────────
  static const int coinsPerDollar = 10000; // 10,000 monedas = $1.00 USD
  static const int minCashoutCoins = 10000; // mínimo $1.00 para cobrar
  static const int maxDailyEarnCoins = 100000; // cap anti-fraude $10/día

  // ── Meta diaria (sube cada día) ───────────────────────────────
  static const int dailyGoalStart = 5000;   // ~5 días de videos para alcanzar
  static const int dailyGoalIncrement = 500;
  static const int dailyGoalMax = 20000;    // techo = $2.00

  // ── Recompensas ───────────────────────────────────────────────
  static const int coinsPerVideo = 30;      // 30 monedas = $0.003 por video
  static const int coinsPerVideoMax = 25;   // max 25 videos/día = 750 monedas
  static const int coinsPerSurvey = 6000;   // ~$0.60 por encuesta (CPX paga ~$1, damos 60%)
  static const int coinsStreak7days = 1000; // bonus racha 7 días = $0.10
  static const int coinsStreak30days = 5000; // bonus racha 30 días = $0.50
  static const int coinsReferral = 1000;   // referido cobra = $0.10

  // ── Supabase ──────────────────────────────────────────────────
  static const String supabaseUrl = 'https://jqxfnvjdgxuqmyjymdnr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxeGZudmpkZ3h1cW15anltZG5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0MTMzNzUsImV4cCI6MjA4OTk4OTM3NX0.PcZOiJtLxNbQw2PZUWU3qvA1liQB9699Vz0OtRDftHg';

  // ── Backend Vercel ────────────────────────────────────────────
  // TODO: reemplazar con tu URL de Vercel
  static const String apiBaseUrl = 'https://juegalo-api.vercel.app';

  // ── AdMob ─────────────────────────────────────────────────────
  static const String admobAppIdAndroid = 'ca-app-pub-5486388630970825~2374341538';
  static const String admobAppIdIos = 'ca-app-pub-XXXXXXXX~XXXXXXXX'; // TODO: agregar cuando tengas iOS en AdMob
  static const String admobRewardedAndroid = 'ca-app-pub-5486388630970825/4840288002';
  static const String admobRewardedIos = 'ca-app-pub-XXXXXXXX/XXXXXXXX'; // TODO: agregar cuando tengas iOS en AdMob

  // ── Adjoe Offerwall ───────────────────────────────────────────
  // TODO: reemplazar con tu App ID de adjoe.io → Publishers
  static const String adjoeAppId = 'ADJOE_APP_ID';

  // ── Tapjoy Offerwall ──────────────────────────────────────────
  // TODO: reemplazar con tu API key de publishers.tapjoy.com
  static const String tapjoyApiKey = 'TAPJOY_API_KEY';

  // ── Revenue share ─────────────────────────────────────────────
  static const double revenueShareUser = 0.60; // 60% al usuario
  static const double revenueShareApp = 0.40; // 40% para la app
}
