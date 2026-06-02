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
  static const int coinsPerVideo = 25;      // 25 monedas = $0.0025 por video
  static const int coinsPerVideoMax = 50;   // max 50 videos/día = 1,500 monedas
  // ── CPX Research — economía de encuestas ─────────────────────────
  // Estos valores DEBEN coincidir con las env vars del servidor:
  //   CPX_COINS_DIVISOR=2  CPX_COINS_MAX=5000  CPX_COINS_MIN=100
  static const double cpxCoinsDivisor = 2.0;  // divide amount_local de CPX
  static const int    cpxCoinsMax     = 5000; // máximo por encuesta
  static const int    cpxCoinsMin     = 100;  // mínimo por encuesta
  static const int coinsStreak7days = 200;  // bonus racha 7 días = $0.02
  static const int coinsStreak30days = 500; // bonus racha 30 días = $0.05
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
  static const String admobAppIdIos = 'ca-app-pub-5486388630970825~4509192467';
  static const String admobRewardedAndroid = 'ca-app-pub-5486388630970825/4840288002';
  static const String admobRewardedIos = 'ca-app-pub-5486388630970825/3159932254';

  // ── Adjoe Offerwall ───────────────────────────────────────────
  static const String adjoeAppId = 'f14232cebeb8b5da05f61268cdcc876f';

  // ── Tapjoy Offerwall ──────────────────────────────────────────
  // TODO: reemplazar con tu API key de publishers.tapjoy.com
  static const String tapjoyApiKey = 'TAPJOY_API_KEY';

  // ── Revenue share ─────────────────────────────────────────────
  static const double revenueShareUser = 0.60; // 60% al usuario
  static const double revenueShareApp = 0.40; // 40% para la app
}
