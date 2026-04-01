class AppConstants {
  AppConstants._();

  // ── App info ──────────────────────────────────────────────────
  static const String appName = 'JUEGALO';
  static const String appTagline = 'Gana Dinero Real';

  // ── Sistema de monedas ────────────────────────────────────────
  static const int coinsPerDollar = 1000; // 1,000 monedas = $1.00 USD
  static const int minCashoutCoins = 1000; // mínimo $1.00 para cobrar
  static const int maxDailyEarnCoins = 50000; // cap anti-fraude $50/día

  // ── Meta diaria (sube cada día) ───────────────────────────────
  static const int dailyGoalStart = 1500;
  static const int dailyGoalIncrement = 250;
  static const int dailyGoalMax = 5000;

  // ── Recompensas ───────────────────────────────────────────────
  static const int coinsPerVideo = 50;
  static const int coinsPerVideoMax = 20; // max videos por día
  static const int coinsPerSurvey = 200;  // monedas por encuesta CPX
  static const int coinsStreak7days = 1000; // bonus racha 7 días
  static const int coinsStreak30days = 5000; // bonus racha 30 días
  static const int coinsReferral = 1000; // cuando referido cobra $1

  // ── Supabase ──────────────────────────────────────────────────
  static const String supabaseUrl = 'https://jqxfnvjdgxuqmyjymdnr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxeGZudmpkZ3h1cW15anltZG5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0MTMzNzUsImV4cCI6MjA4OTk4OTM3NX0.PcZOiJtLxNbQw2PZUWU3qvA1liQB9699Vz0OtRDftHg';

  // ── Backend Vercel ────────────────────────────────────────────
  // TODO: reemplazar con tu URL de Vercel
  static const String apiBaseUrl = 'https://juegalo-api.vercel.app';

  // ── AdMob ─────────────────────────────────────────────────────
  // TODO: reemplazar con tus IDs reales de AdMob
  static const String admobAppIdAndroid = 'ca-app-pub-XXXXXXXX~XXXXXXXX';
  static const String admobAppIdIos = 'ca-app-pub-XXXXXXXX~XXXXXXXX';
  static const String admobRewardedAndroid = 'ca-app-pub-XXXXXXXX/XXXXXXXX';
  static const String admobRewardedIos = 'ca-app-pub-XXXXXXXX/XXXXXXXX';

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
