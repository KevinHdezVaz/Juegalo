// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get tutorialWelcomeTitle => '¡Bienvenido a JUEGALO!';

  @override
  String get tutorialWelcomeSubtitle =>
      'La app donde juegas, haces\nencuestas y ganas dinero real.';

  @override
  String get tutorialWelcomeFree => '100% gratis para siempre';

  @override
  String get tutorialWelcomeFreeValue => 'Sin cargos';

  @override
  String get tutorialWelcomeLatam => 'Disponible en Latinoamérica';

  @override
  String get tutorialWelcomeLatamValue => 'Desde hoy';

  @override
  String get tutorialWelcomeStart => 'Empieza a ganar en 1 minuto';

  @override
  String get tutorialWelcomeStartValue => 'Rápido';

  @override
  String get tutorialEarnTitle => 'Gana monedas fácil';

  @override
  String get tutorialEarnSubtitle =>
      'Tres formas de acumular\nmonedas cada día.';

  @override
  String get tutorialEarnVideos => 'Videos cortos';

  @override
  String get tutorialEarnVideosValue => '+50 monedas c/u';

  @override
  String get tutorialEarnSurveys => 'Encuestas';

  @override
  String get tutorialEarnSurveysValue => 'hasta 500 monedas';

  @override
  String get tutorialEarnGames => 'Juegos';

  @override
  String get tutorialEarnGamesValue => 'hasta 2,000 monedas';

  @override
  String get tutorialRankingTitle => 'Ranking semanal';

  @override
  String get tutorialRankingSubtitle =>
      'Compite cada semana.\nLos mejores ganan premios extra.';

  @override
  String get tutorialRankingFirst => 'Puesto #1';

  @override
  String get tutorialRankingFirstValue => '2,500 monedas';

  @override
  String get tutorialRankingSecond => 'Puesto #2';

  @override
  String get tutorialRankingSecondValue => '1,000 monedas';

  @override
  String get tutorialRankingThird => 'Puesto #3';

  @override
  String get tutorialRankingThirdValue => '500 monedas';

  @override
  String get tutorialCashoutTitle => 'Cobra cuando quieras';

  @override
  String get tutorialCashoutSubtitle =>
      '10,000 monedas = \$1.00 USD.\nRetira desde \$1 sin comisión.';

  @override
  String get tutorialCashoutPaypalValue => 'Instantáneo';

  @override
  String get tutorialSkip => 'Saltar';

  @override
  String get tutorialNext => 'Siguiente';

  @override
  String get tutorialStartEarning => '¡Empezar a ganar!';

  @override
  String get onboardingTagline => 'Juega. Gana. Cobra.';

  @override
  String get onboardingPaidBadge => '+\$12,847 pagados';

  @override
  String get onboardingHowItWorks => '¿Cómo funciona?';

  @override
  String get onboardingFeaturePlay => 'Juega';

  @override
  String get onboardingFeaturePlaySubtitle =>
      'Instala juegos gratis y acumula monedas';

  @override
  String get onboardingFeatureSurveys => 'Encuestas';

  @override
  String get onboardingFeatureSurveysSubtitle =>
      'Gana monedas por cada encuesta completada';

  @override
  String get onboardingFeatureCashout => 'Cobra';

  @override
  String get onboardingFeatureCashoutSubtitle =>
      'Retira a PayPal desde \$1 USD';

  @override
  String get onboardingStartNow => 'Empieza ahora';

  @override
  String get onboardingContinueGoogle => 'Continuar con Google';

  @override
  String get onboardingContinueApple => 'Continuar con Apple';

  @override
  String get onboardingContinueEmail => 'Continuar con correo';

  @override
  String get onboardingPlayGuest => 'Jugar sin cuenta';

  @override
  String get onboardingLegal =>
      'Al continuar aceptas los Términos de uso\ny la Política de privacidad';

  @override
  String get onboardingOr => 'o';

  @override
  String get onboardingErrorWrongCredentials =>
      'Correo o contraseña incorrectos';

  @override
  String onboardingErrorGeneric(String msg) {
    return 'Error al entrar: $msg';
  }

  @override
  String get emailDialogTitle => 'Iniciar sesión';

  @override
  String get emailDialogSubtitle => 'Correo y contraseña';

  @override
  String get emailDialogEmail => 'Correo electrónico';

  @override
  String get emailDialogPassword => 'Contraseña';

  @override
  String get emailDialogSignIn => 'Entrar';

  @override
  String get homeTabGames => 'Juegos';

  @override
  String get homeTabSurveys => 'Encuestas';

  @override
  String get homeTabVideos => 'Videos';

  @override
  String get homeTabRanking => 'Ranking';

  @override
  String get homeTabWallet => 'Cobrar';

  @override
  String get balanceCardLabel => 'Tu saldo';

  @override
  String balanceCardCoins(String coins) {
    return '$coins monedas';
  }

  @override
  String get balanceCardCashout => 'Cobrar';

  @override
  String get dailyBonusTitle => 'Bono diario';

  @override
  String get dailyBonusStreakZero => 'Comienza tu racha hoy';

  @override
  String dailyBonusStreakOne(int count) {
    return '$count día seguido';
  }

  @override
  String dailyBonusStreakMany(int count) {
    return '$count días seguidos';
  }

  @override
  String dailyBonusDays(int count) {
    return '$count días';
  }

  @override
  String get dailyBonusClaimed => 'Reclamado hoy';

  @override
  String get dailyBonusTodayPrize => 'Premio de hoy';

  @override
  String dailyBonusCoins(String coins) {
    return '+$coins monedas';
  }

  @override
  String dailyBonusNextMilestone(int day, String coins) {
    return 'Día $day → +$coins monedas';
  }

  @override
  String get dailyBonusClaimedBadge => 'Reclamado';

  @override
  String get dailyBonusDayMon => 'Lun';

  @override
  String get dailyBonusDayTue => 'Mar';

  @override
  String get dailyBonusDayWed => 'Mié';

  @override
  String get dailyBonusDayThu => 'Jue';

  @override
  String get dailyBonusDayFri => 'Vie';

  @override
  String get dailyBonusDaySat => 'Sáb';

  @override
  String get dailyBonusDaySun => 'Dom';

  @override
  String get dailyGoalReached => '¡Meta! +1,500 🎯';

  @override
  String get dailyGoalLabel => 'Meta de hoy';

  @override
  String dailyGoalRemaining(String coins) {
    return 'Faltan $coins monedas para el bono de 1,500 monedas gratis.';
  }

  @override
  String get profileTitle => 'Mi perfil';

  @override
  String get profileCurrentCoins => 'Monedas actuales';

  @override
  String get profileTotalEarned => 'Total ganado (USD)';

  @override
  String get profileCurrentStreak => 'Racha actual';

  @override
  String profileStreakDays(int days) {
    return '$days días';
  }

  @override
  String get profileSignOut => 'Cerrar sesión';

  @override
  String get profileDeleteAccount => 'Eliminar mi cuenta';

  @override
  String get profileIdCopied => 'ID copiado al portapapeles';

  @override
  String get profilePhotoUpdated => '¡Foto actualizada!';

  @override
  String profilePhotoError(String error) {
    return 'Error al subir foto: $error';
  }

  @override
  String get profileTakePhoto => 'Tomar foto';

  @override
  String get profileChooseGallery => 'Elegir de galería';

  @override
  String get profileDeleteTitle => 'Eliminar cuenta';

  @override
  String get profileDeleteContent =>
      'Esta acción es irreversible.\n\nSe eliminarán tu perfil, historial y saldo de monedas. Las solicitudes de cobro pendientes se conservan 90 días por obligación legal.\n\n¿Estás seguro de que quieres continuar?';

  @override
  String get profileDeleteConfirm => 'Sí, eliminar';

  @override
  String get profileCancel => 'Cancelar';

  @override
  String get profileConnectionError => 'Error de conexión. Intenta de nuevo.';

  @override
  String get profileVerifiedAccount => 'Cuenta verificada';

  @override
  String get profileNoEmail => 'Sin correo registrado';

  @override
  String get profileGuestTitle => 'Estás como invitado';

  @override
  String get profileGuestSubtitle =>
      'Vincula tu cuenta para no perder tus monedas';

  @override
  String get profileLinkGoogle => 'Vincular con Google';

  @override
  String get profileLinkApple => 'Vincular con Apple';

  @override
  String get profileLinkEmail => 'Vincular con correo';

  @override
  String get profileCoinsPreserved =>
      'Tus monedas se conservan al vincular tu cuenta.';

  @override
  String get profileLinkEmailTitle => 'Vincular con correo';

  @override
  String get profileLinkEmailSubtitle => 'Tus monedas se conservan.';

  @override
  String get profileConfirmPassword => 'Confirmar contraseña';

  @override
  String get profileLinkSave => 'Vincular y guardar monedas';

  @override
  String get profilePasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get profilePasswordTooShort => 'Mínimo 6 caracteres';

  @override
  String get profileLinkedGoogle => '¡Cuenta vinculada con Google!';

  @override
  String get profileLinkedApple => '¡Cuenta vinculada con Apple!';

  @override
  String get profileLinkedEmail =>
      '¡Cuenta creada! Tus monedas se conservaron.';

  @override
  String get referralInviteFriends => 'Invita amigos';

  @override
  String get referralBothEarn => 'Ganan 1,000 monedas los dos';

  @override
  String get referralYourCode => 'Tu código';

  @override
  String get referralCopy => 'Copiar';

  @override
  String get referralShare => 'Compartir código';

  @override
  String referralShareMessage(String code) {
    return '¡Únete a JUEGALO y gana dinero real jugando, completando encuestas y viendo videos! 🎮💰\n\nUsa mi código al registrarte y los dos ganamos 1,000 monedas cuando hagas tu primer cobro.\n\n📱 Código: $code\n\nDescarga la app: juegalo.app';
  }

  @override
  String get referralShareSubject => 'Gana dinero con JUEGALO';

  @override
  String get referralCodeCopied => 'Código copiado al portapapeles';

  @override
  String get referralBonusPaid => 'Bono de referido recibido';

  @override
  String get referralBonusPending => 'Bono pendiente';

  @override
  String get referralBonusPaidDesc =>
      '+1,000 monedas ya fueron agregadas a tu cuenta.';

  @override
  String get referralBonusPendingDesc =>
      'Recibirás 1,000 monedas al hacer tu primer cobro.';

  @override
  String get referralRegisterCode => '¿Te invitó alguien? Registra su código';

  @override
  String get referralCount => 'Referidos';

  @override
  String get referralEarnings => 'Monedas ganadas';

  @override
  String get referralDialogTitle => '¿Te invitó alguien?';

  @override
  String get referralDialogSubtitle => 'Ingresa el código de tu amigo.';

  @override
  String get referralBothGet =>
      'Los dos reciben 1,000 monedas cuando hagas tu primer cobro.';

  @override
  String get referralApplyCode => 'Aplicar código';

  @override
  String get referralHowTitle => 'Cómo funciona el bono';

  @override
  String get referralHowStep1 => 'Ingresa el código de quien te invitó.';

  @override
  String get referralHowStep2 =>
      'Tú y tu amigo reciben 1,000 monedas cada uno.';

  @override
  String get referralHowStep3 =>
      'El bono se acredita cuando tú completes tu primer cobro exitoso.';

  @override
  String get referralHowStep4 =>
      'Solo puedes registrar un código una vez y antes de tu primer cobro.';

  @override
  String get referralHowGotIt => 'Entendido';

  @override
  String get referralRegistered =>
      '🎁 ¡Código registrado! El bono (1,000 monedas c/u) se acredita cuando hagas tu primer cobro.';

  @override
  String get rankingTitle => 'Ranking Semanal';

  @override
  String get rankingSubtitle => 'Top jugadores de la semana';

  @override
  String get rankingResetsMonday => 'Se reinicia cada lunes';

  @override
  String get rankingBeFirst => '¡Sé el primero!';

  @override
  String get rankingEmptyDesc =>
      'Nadie ha ganado monedas esta semana.\nEl ranking se llena conforme los jugadores compiten.';

  @override
  String get rankingMyPosition => 'Tu posición actual';

  @override
  String get rankingEarnToClimb => 'Gana monedas para subir';

  @override
  String get rankingTipGames => 'Instala juegos y completa misiones';

  @override
  String get rankingSurveysTip => 'Completa encuestas y gana rápido';

  @override
  String get rankingVideosTip => 'Ve 20 videos diarios para acumular';

  @override
  String rankingPositions(int total) {
    return 'POSICIONES 4 – $total';
  }

  @override
  String get rankingMyPositionBar => 'Tu posición esta semana';

  @override
  String get rankingKeepPlaying => '¡Sigue jugando para subir!';

  @override
  String get rankingLoadError => 'No se pudo cargar el ranking';

  @override
  String get rankingRetry => 'Reintentar';

  @override
  String get rankingYou => 'TÚ';

  @override
  String get surveysTitle => 'Encuestas disponibles';

  @override
  String surveysUpdated(String time) {
    return 'Actualizado $time';
  }

  @override
  String surveysCount(int count, String time) {
    return '$count encuesta • $time';
  }

  @override
  String surveysCountPlural(int count, String time) {
    return '$count encuestas • $time';
  }

  @override
  String get surveysRefresh => 'Actualizar';

  @override
  String get surveysEarn => 'Ganas ';

  @override
  String get surveysPerSurvey => ' por cada encuesta completada';

  @override
  String get surveysEmpty => 'No hay encuestas disponibles';

  @override
  String get surveysEmptySubtitle => 'Vuelve más tarde o toca actualizar';

  @override
  String surveysTimeAgoSeconds(int sec) {
    return 'hace ${sec}s';
  }

  @override
  String surveysTimeAgoMinutes(int min) {
    return 'hace $min min';
  }

  @override
  String surveysTimeAgoHours(int hr) {
    return 'hace ${hr}h';
  }

  @override
  String surveysCoinsEarned(String coins) {
    return '+$coins monedas — encuesta completada';
  }

  @override
  String get videosTitle => 'Videos disponibles';

  @override
  String get videosTodayTitle => 'Videos de hoy';

  @override
  String videosEarnedToday(int coins) {
    return '$coins monedas ganadas hoy';
  }

  @override
  String get videosLimitReached => 'Límite diario alcanzado';

  @override
  String get videosResetsIn => 'Vídeos disponibles en';

  @override
  String get videosRetry => 'Reintentar';

  @override
  String get videosUnavailable => 'No disponible\nahora';

  @override
  String get videosWatch => 'Ver';

  @override
  String get videosHowItWorks => 'Cómo funciona';

  @override
  String get videosInfoFull => 'Ve el anuncio completo para ganar monedas';

  @override
  String get videosInfoLimit => 'Límite de 50 anuncios por día';

  @override
  String get videosInfoCoins => '30 monedas por anuncio completado';

  @override
  String get videosInfoAccumulate =>
      'Acumula 10,000 monedas para cobrar \$1.00';

  @override
  String get videosAvailabilityNote =>
      'Los anuncios se cargan según disponibilidad. Si no aparecen, toca \"Reintentar\" en unos segundos.';

  @override
  String videosCoinsEarned(int coins) {
    return '+$coins monedas ganadas';
  }

  @override
  String videosErrorCredit(String error) {
    return 'Error al acreditar monedas: $error';
  }

  @override
  String videosSlot(int number) {
    return 'Video $number';
  }

  @override
  String get walletErrorLoading => 'Error al cargar';

  @override
  String walletCoinsAvailable(String coins) {
    return '$coins monedas disponibles';
  }

  @override
  String get walletRequestCashout => 'Solicitar cobro';

  @override
  String get walletMinimumCashout => 'Mínimo \$1.00 para retirar';

  @override
  String get walletPaymentMethods => 'Métodos de cobro';

  @override
  String get walletPaypalDesc => 'Internacional · 1–3 días hábiles';

  @override
  String get walletMercadopagoDesc => 'México y LatAm · sin comisión';

  @override
  String get walletComingSoon => 'Próximamente';

  @override
  String get walletComingSoonFull => 'Próximamente disponible';

  @override
  String get walletTransactions => 'Últimas transacciones';

  @override
  String get walletNoTransactions => 'Sin transacciones aún';

  @override
  String get walletAlmostThere => '¡Casi llegas!';

  @override
  String walletNeedCoins(String coins, String missing) {
    return 'Necesitas al menos $coins monedas (\$1.00 USD) para retirar.\n\nTe faltan $missing monedas.';
  }

  @override
  String get walletGotIt => 'Entendido';

  @override
  String get cashoutStepRequested => 'Solicitado';

  @override
  String get cashoutStepRequestedSub => 'Recibimos tu solicitud';

  @override
  String get cashoutStepReview => 'En revisión';

  @override
  String get cashoutStepReviewSub => 'Verificando los datos';

  @override
  String get cashoutStepProcessing => 'Procesando';

  @override
  String get cashoutStepProcessingSub => 'Enviando el pago';

  @override
  String get cashoutStepPaid => 'Pagado';

  @override
  String get cashoutStepPaidSub => '¡Dinero enviado!';

  @override
  String get cashoutStatusPending => 'Pendiente';

  @override
  String get cashoutStatusProcessing => 'En proceso';

  @override
  String get cashoutStatusPaid => 'Pagado';

  @override
  String get cashoutStatusRejected => 'Rechazado';

  @override
  String cashoutRequestHeader(String amount, String method) {
    return 'Cobro de \$$amount USD · $method';
  }

  @override
  String get cashoutPaidBanner => '¡Tu pago fue enviado!';

  @override
  String get cashoutPaidBannerSub => 'Revisa tu cuenta de PayPal.';

  @override
  String get cashoutReferralBanner => '¡Código de referido cobrado!';

  @override
  String get cashoutReferralBannerSub =>
      'Tú y tu amigo ya tienen sus 1,000 monedas.';

  @override
  String get cashoutTimePending =>
      'Tiempo estimado: 1–3 días hábiles. Te avisaremos cuando sea enviado.';

  @override
  String get cashoutTimeProcessing =>
      'Tu pago está siendo procesado. Llegará pronto a tu cuenta.';

  @override
  String cashoutPaidOn(String date, String time) {
    return 'Pagado el $date a las $time';
  }

  @override
  String cashoutRequestedOn(String date, String time) {
    return 'Solicitado el $date a las $time';
  }

  @override
  String get cashoutAppTitle => 'Solicitar cobro';

  @override
  String get cashoutAmountTitle => 'Monto a cobrar';

  @override
  String get cashoutMethodTitle => 'Método de cobro';

  @override
  String get cashoutAccountTitle => 'Datos de tu cuenta';

  @override
  String get cashoutSummaryAmount => 'Monto';

  @override
  String get cashoutSummaryCoins => 'Monedas a descontar';

  @override
  String get cashoutSummaryMethod => 'Método';

  @override
  String cashoutConfirm(String amount) {
    return 'Confirmar cobro de \$$amount';
  }

  @override
  String get cashoutProcessingNote => 'Procesamos tu pago en 1–3 días hábiles';

  @override
  String get cashoutEnterAccount => 'Ingresa los datos de tu cuenta';

  @override
  String get cashoutSentSuccess =>
      '¡Solicitud enviada! Procesamos en 1-3 días hábiles';

  @override
  String cashoutUsdAvailable(String usd) {
    return '\$$usd USD disponibles';
  }

  @override
  String cashoutCoins(String coins) {
    return '$coins monedas';
  }

  @override
  String cashoutNeedCoins(String coins, String missing) {
    return 'Necesitas al menos $coins monedas (\$1.00 USD) para retirar por PayPal.\n\nTe faltan $missing monedas.';
  }

  @override
  String get cashoutGuestTitle => 'Crea una cuenta para cobrar';

  @override
  String get cashoutGuestSubtitle =>
      'Estás jugando como invitado. Vincula tu cuenta\ny conserva todas las monedas que ganaste.';

  @override
  String get cashoutGuestCurrentCoins => 'Tus monedas actuales';

  @override
  String cashoutGuestCoins(String coins) {
    return '$coins monedas';
  }

  @override
  String get cashoutGuestContinueGoogle => 'Continuar con Google';

  @override
  String get cashoutGuestContinueApple => 'Continuar con Apple';

  @override
  String get cashoutGuestCreateEmail => 'Crear cuenta con correo';

  @override
  String get cashoutGuestNote =>
      'Tus monedas se transferirán automáticamente\na tu cuenta nueva.';

  @override
  String get cashoutGuestLinked =>
      '¡Cuenta vinculada! Tus monedas se conservaron.';

  @override
  String get cashoutGuestCreated =>
      '¡Cuenta creada! Tus monedas se conservaron.';

  @override
  String get profileFirstName => 'Nombre';

  @override
  String get profileLastName => 'Apellido';

  @override
  String cashoutMinLabel(String usd) {
    return '$usd mín';
  }

  @override
  String cashoutMaxLabel(String usd) {
    return '$usd máx';
  }

  @override
  String cashoutGuestLinkedErrorGoogle(String error) {
    return 'Error al vincular con Google: $error';
  }

  @override
  String cashoutGuestLinkedErrorApple(String error) {
    return 'Error al vincular con Apple: $error';
  }

  @override
  String get cashoutCreateEmailTitle => 'Crear cuenta con correo';

  @override
  String get cashoutCreateEmailSubtitle =>
      'Tus monedas se conservarán automáticamente.';

  @override
  String get cashoutCreateEmailButton => 'Crear cuenta y conservar monedas';

  @override
  String get cashoutPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get cashoutPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get cashoutPaypalSubtitle =>
      'Internacional · procesamos en 1–3 días hábiles';

  @override
  String get cashoutMercadopagoSubtitle => 'Próximamente disponible';

  @override
  String get gamesTitle => 'Ofertas y Juegos';

  @override
  String get gamesAvailable => '🎮 ¡Ya disponible!';

  @override
  String get gamesSoon => '🚀 Próximamente';

  @override
  String get gamesDescription =>
      'Instala juegos y apps para ganar\nmonedas extra sin ver anuncios.';

  @override
  String get gamesOpenButton => '🎮  Ver Juegos y Ganar';

  @override
  String get gamesExploreSoon => '🔓  Ver Catálogo';

  @override
  String get gamesInstallGames => 'Instala juegos';

  @override
  String get gamesInstallGamesDesc =>
      'Gana monedas por instalar y jugar nuevos juegos.';

  @override
  String get gamesDownloadApps => 'Descarga apps';

  @override
  String get gamesDownloadAppsDesc =>
      'Completa tareas en apps y recibe monedas al instante.';

  @override
  String get gamesCompleteMissions => 'Completa misiones';

  @override
  String get gamesCompleteMissionsDesc =>
      'Llega a un nivel específico en un juego y gana mucho más.';

  @override
  String get gamesOpenCatalog =>
      'Toca el botón de arriba para ver el catálogo completo de juegos y ofertas.';

  @override
  String get gamesComingNotify =>
      'Te avisaremos cuando esta sección esté disponible.';

  @override
  String get gamesOpenError =>
      'No se pudo abrir el catálogo. Inténtalo de nuevo.';

  @override
  String get gamesComingSoonTitle => 'Próximamente';

  @override
  String get gamesComingSoonContent =>
      'Esta sección estará disponible muy pronto.\n¡Te avisaremos cuando puedas ganar monedas instalando juegos!';

  @override
  String get gamesComingSoonButton => 'Entendido';

  @override
  String get gamesStatusActive => 'ACTIVO';

  @override
  String get gamesStatusSoon => 'PRÓXIMAMENTE';

  @override
  String get gamesHeroTitle => '¡Juega y Gana\nMonedas Reales! 🎮';

  @override
  String get gamesHeroSubtitle =>
      'Descarga juegos, completa misiones\ny acumula monedas canjeables.';

  @override
  String get gamesPopularTitle => 'Juegos Populares';

  @override
  String get gamesSeeAll => 'Ver todos →';

  @override
  String get gamesStatGames => '50+ juegos';

  @override
  String get gamesStatReward => 'Hasta 5,000 🪙';

  @override
  String get gamesStatInstant => 'Crédito inmediato';

  @override
  String get gamesHowTitle => '¿Cómo funciona?';

  @override
  String get gamesStep1Title => 'Descarga un juego';

  @override
  String get gamesStep1Desc =>
      'Elige cualquier juego del catálogo y descárgalo gratis.';

  @override
  String get gamesStep2Title => 'Juega y completa misiones';

  @override
  String get gamesStep2Desc =>
      'Alcanza los niveles o metas indicadas en la oferta.';

  @override
  String get gamesStep3Title => '¡Gana monedas!';

  @override
  String get gamesStep3Desc =>
      'Las monedas se acreditan automáticamente al completar.';

  @override
  String get gamesFreeLabel => 'GRATIS';

  @override
  String get gamesMaintenanceTitle => 'Juegos en mantenimiento';

  @override
  String get gamesMaintenanceSubtitle =>
      'Estamos preparando algo increíble.\nVuelve en unas horas.';

  @override
  String get dailyBonusClaimedToast => '¡Bono diario reclamado!';

  @override
  String dailyBonusCoinsAndStreak(int coins, int streak, String streakLabel) {
    return '+$coins monedas • Racha de $streak $streakLabel';
  }

  @override
  String get dailyBonusStreakLabelOne => 'día';

  @override
  String get dailyBonusStreakLabelMany => 'días';

  @override
  String get dailyGoalReachedToast => '¡Meta diaria alcanzada!';

  @override
  String dailyGoalBonusCoins(String coins) {
    return '+$coins monedas de bono';
  }

  @override
  String get profileEditNameTitle => 'Editar nombre';

  @override
  String get profileEditNameHint => 'Tu nombre';

  @override
  String get profileSave => 'Guardar';

  @override
  String get profileNameUpdated => '✅ Nombre actualizado';

  @override
  String get profileLanguageTitle => 'Idioma';

  @override
  String get profileLanguageSubtitle => 'Español / English / Português';

  @override
  String get profileLanguageDialogTitle => 'Selecciona el idioma';

  @override
  String get profileLanguageEs => '🇲🇽  Español';

  @override
  String get profileLanguageEn => '🇺🇸  English';

  @override
  String get profileLanguagePt => '🇧🇷  Português';

  @override
  String get profileLanguageAuto => 'Automático (dispositivo)';

  @override
  String get versionUpdateTitle => '¡Actualización requerida!';

  @override
  String get versionUpdateBody =>
      'Para seguir ganando dinero con JUEGALO necesitas instalar la última versión. ¡Trae mejoras y más formas de ganar!';

  @override
  String get versionUpdateButton => 'Actualizar ahora';

  @override
  String get versionUpdateNote =>
      'La actualización es gratuita y solo toma unos segundos.';

  @override
  String get versionNewAvailable => '🚀 Nueva versión disponible';

  @override
  String get rankingPos1 => 'Puesto #1';

  @override
  String get rankingPos2 => 'Puesto #2';

  @override
  String get rankingPos3 => 'Puesto #3';

  @override
  String get rankingTop50 => 'TOP 50';

  @override
  String get rankingTop3Label => 'TOP 3';

  @override
  String get rankingThisWeek => 'esta semana';

  @override
  String rankingStreakDays(int days) {
    return '$days días consecutivos';
  }

  @override
  String get rankingCelebFirst => '¡Primer lugar!';

  @override
  String get rankingCelebSecond => '¡Segundo lugar!';

  @override
  String get rankingCelebThird => '¡Tercer lugar!';

  @override
  String get rankingCelebSubtitle =>
      'La semana pasada fuiste uno\nde los mejores jugadores.';

  @override
  String get rankingCelebCoinsLabel => 'monedas acreditadas';

  @override
  String get rankingCelebButton => '¡Genial! 🎉';

  @override
  String get rankingInfoTitle => '¿Cómo funciona el ranking?';

  @override
  String get rankingInfoSubtitle =>
      'Sé de los mejores jugadores de la semana\ny obtén recompensas en monedas.';

  @override
  String get rankingInfoFirst => 'Primer lugar';

  @override
  String get rankingInfoFirstDesc =>
      'El jugador con más monedas acumuladas en la semana gana';

  @override
  String get rankingInfoSecond => 'Segundo lugar';

  @override
  String get rankingInfoSecondDesc => 'Segundo puesto al cierre semanal gana';

  @override
  String get rankingInfoThird => 'Tercer lugar';

  @override
  String get rankingInfoThirdDesc => 'Tercer puesto al cierre semanal gana';

  @override
  String get rankingInfoHowToEarn => '💡 ¿Cómo acumular monedas?';

  @override
  String get rankingInfoTipGames => 'Instala juegos y completa misiones';

  @override
  String get rankingInfoTipSurveys => 'Completa encuestas diarias';

  @override
  String get rankingInfoTipVideos => 'Ve hasta 20 videos al día';

  @override
  String get rankingInfoTipStreak => 'Mantén tu racha diaria para bonos extra';

  @override
  String get rankingInfoGotIt => '¡Entendido!';

  @override
  String get rankingLastWinnersTitle => '🏆  GANADORES DE LA SEMANA PASADA';

  @override
  String get rankingLastWinnersPrize => 'premio';

  @override
  String get txHistoryTitle => 'Historial completo';

  @override
  String get txFilterAll => 'Todos';

  @override
  String get txFilterVideos => 'Videos';

  @override
  String get txFilterSurveys => 'Encuestas';

  @override
  String get txFilterBonus => 'Bonos';

  @override
  String get txFilterCashout => 'Cobros';

  @override
  String get txGroupToday => 'Hoy';

  @override
  String get txGroupYesterday => 'Ayer';

  @override
  String get txGroupThisWeek => 'Esta semana';

  @override
  String get txGroupThisMonth => 'Este mes';

  @override
  String get txGroupOlder => 'Anterior';

  @override
  String get txLoadMore => 'Cargar más';

  @override
  String get txEmpty => 'Sin transacciones aún';

  @override
  String get txEmptyFilter => 'Sin transacciones de este tipo';

  @override
  String get txSeeAll => 'Ver todo';

  @override
  String get phoneVerifyInvalidNumber => 'Ingresa un número de teléfono válido';

  @override
  String get phoneVerifyUnexpectedError =>
      'Error inesperado. Intenta de nuevo.';

  @override
  String get phoneVerifyCodeLength => 'El código tiene 6 dígitos';

  @override
  String get phoneVerifyErrorInvalidExpired =>
      'Código incorrecto o expirado. Solicita uno nuevo.';

  @override
  String get phoneVerifyErrorRateLimit =>
      'Demasiados intentos. Espera unos minutos.';

  @override
  String get phoneVerifyErrorAlreadyRegistered =>
      'Este número ya está registrado en otra cuenta. Usa un número diferente.';

  @override
  String get phoneVerifyErrorInvalidPhone =>
      'Número de teléfono inválido. Verifica el formato e intenta de nuevo.';

  @override
  String get phoneVerifyErrorNetwork =>
      'Error de conexión. Verifica tu internet e intenta de nuevo.';

  @override
  String get phoneVerifyErrorGeneric =>
      'Ocurrió un error inesperado. Intenta de nuevo.';

  @override
  String get phoneVerifyTitleOtpSent => 'Código enviado';

  @override
  String get phoneVerifyTitleEnterPhone => 'Verifica tu número';

  @override
  String phoneVerifySubtitleOtpSent(String phone) {
    return 'Ingresa el código de 6 dígitos\nque enviamos a $phone';
  }

  @override
  String get phoneVerifySubtitlePhone =>
      'Un paso rápido para proteger\ntu dinero. Solo se hace una vez.';

  @override
  String get phoneVerifyStep1of2 => 'Paso 1 de 2';

  @override
  String get phoneVerifyStep2of2 => 'Paso 2 de 2';

  @override
  String get phoneVerifyLabelPhone => 'Número de teléfono';

  @override
  String get phoneVerifyLabelCode => 'Código de verificación';

  @override
  String get phoneVerifyButtonVerify => 'Verificar código';

  @override
  String get phoneVerifyButtonSend => 'Enviar SMS';

  @override
  String phoneVerifyResendIn(int secs) {
    return 'Reenviar en ${secs}s';
  }

  @override
  String get phoneVerifyResend => 'Reenviar código';

  @override
  String get phoneVerifyChangeNumber => 'Cambiar número';

  @override
  String get phoneVerifyPrivacyNote =>
      'Tu número solo se usa para verificar tu identidad. No recibirás spam.';

  @override
  String get phoneVerifyCountryPickerTitle => 'Selecciona tu país';

  @override
  String get phoneVerifyCountrySearch => 'Buscar país o código...';

  @override
  String get phoneVerifyNoResults => 'Sin resultados';

  @override
  String get cashoutPhoneRequired =>
      'Debes verificar tu teléfono para retirar monedas';

  @override
  String get cashoutGateTitle => 'Verifica tu teléfono\npara cobrar';

  @override
  String get cashoutGateStep1Title => 'Ingresa tu número';

  @override
  String get cashoutGateStep1Subtitle => 'Con código de país (+52, +1…)';

  @override
  String get cashoutGateStep2Title => 'Recibe el SMS';

  @override
  String get cashoutGateStep2Subtitle => 'Código de 6 dígitos en segundos';

  @override
  String get cashoutGateStep3Title => '¡Listo para cobrar!';

  @override
  String get cashoutGateStep3Subtitle => 'Nunca más se te pedirá';

  @override
  String get cashoutGateButton => 'Verificar mi teléfono';

  @override
  String get cashoutCurrencyTitle => 'Selecciona la moneda';

  @override
  String cashoutCurrencyCount(int count) {
    return '$count divisas';
  }

  @override
  String get cashoutCurrencySearch => 'Buscar moneda o código (USD, EUR…)';

  @override
  String get profileUnverifiedAccount => 'Cuenta sin verificar';

  @override
  String get dailyBonusNoActivity =>
      'Completa al menos un video o encuesta hoy para reclamar el bono.';

  @override
  String get dailyBonusErrorClaiming =>
      'Error al reclamar el bono. Intenta de nuevo.';

  @override
  String get dailyBonusAvailableIn => 'Disponible en';

  @override
  String get splashLoading => 'Cargando...';

  @override
  String get rankingDefaultUsername => 'Jugador';

  @override
  String get videosMaintenance => 'Videos en mantenimiento.';

  @override
  String get videosUnlocksIn => 'Se desbloquea en';

  @override
  String get surveysMaintenance => 'Encuestas en mantenimiento.';

  @override
  String get surveysMaintenanceSub =>
      'Las encuestas están en pausa.\nRegresamos pronto con más oportunidades.';

  @override
  String get walletLinkAccount => 'Vincular';

  @override
  String get cashoutTabRequest => 'Solicitar';

  @override
  String get cashoutTabPayments => 'Mis pagos';

  @override
  String get cashoutSectionAmount => 'Monto a cobrar';

  @override
  String get cashoutSectionMethod => 'Método de cobro';

  @override
  String get cashoutSectionDetails => 'Datos de pago';

  @override
  String get cashoutCurrencyLabel => 'Moneda de pago';

  @override
  String get cashoutTrustTitle => 'Pagos garantizados';

  @override
  String get cashoutSuccessCount => 'cobros exitosos';

  @override
  String get cashoutBusinessDays => 'días hábiles';

  @override
  String get cashoutTrustPaypal => 'Pagos reales vía PayPal';

  @override
  String get cashoutTrustPaypalSub => 'Directo a tu cuenta en 2–3 días hábiles';

  @override
  String get cashoutTrustSms => 'Verificación SMS anti-fraude';

  @override
  String get cashoutTrustSmsSub => 'Solo usuarios reales pueden cobrar';

  @override
  String get cashoutTrustUsers => 'Miles ya cobraron';

  @override
  String get cashoutTrustUsersSub =>
      'Úsate a nosotros o no nos uses — los pagos hablan';

  @override
  String get cashoutTrustSupport => 'Soporte humano';

  @override
  String get cashoutTrustSupportSub =>
      'Si hay algún problema lo resolvemos contigo';

  @override
  String get cashoutHistoryLoadError =>
      'No se pudo cargar el historial de cobros.';

  @override
  String get cashoutHistoryEmpty => 'Sin solicitudes aún';

  @override
  String get cashoutReviewNote =>
      '⏱ En revisión — procesamos en 2–3 días hábiles';

  @override
  String get cashoutRejectedNote =>
      'Contacta soporte si crees que esto es un error.';

  @override
  String get cashoutLoadError => 'No se pudo cargar tu información';

  @override
  String get cashoutLoadErrorSub => 'Verifica tu conexión e intenta de nuevo';

  @override
  String cashoutAvailableBalance(String amount) {
    return '$amount USD disponibles';
  }

  @override
  String get cashoutSummaryCurrency => 'Moneda';

  @override
  String get cashoutCreateAccount => 'Crea una cuenta para cobrar';

  @override
  String get cashoutNameDialogContent => 'Ingresa tu nombre y apellido';

  @override
  String get txLoadError => 'No se pudieron cargar tus transacciones.';

  @override
  String get errorNoConnection => 'Sin conexión';

  @override
  String get errorGenericMessage =>
      'No pudimos cargar la información.\nVerifica tu conexión e intenta de nuevo.';

  @override
  String get errorRetry => 'Reintentar';

  @override
  String get maintenanceTitle => 'En mantenimiento temporalmente';

  @override
  String get maintenanceComingSoon => 'Regresamos pronto';

  @override
  String get maintenanceWorking => 'Estamos trabajando en ello. Gracias 🙏';

  @override
  String maintenanceCheckingIn(int secs) {
    return 'Verificando automáticamente en $secs s...';
  }

  @override
  String get maintenanceRetry => 'Reintentar ahora';

  @override
  String get promoMusicMeetBadge => 'NUEVO';

  @override
  String get promoMusicMeetSubtitle =>
      '¡Encuentra gente con tus mismos gustos musicales cerca de ti!';

  @override
  String get promoMusicMeetButton => 'Ver';

  @override
  String get walletMaintenanceSubtitle =>
      'Estamos procesando pagos pendientes.\nVuelve en unas horas para solicitar tu retiro.';

  @override
  String get walletGuestWarning =>
      'Jugando como invitado. Vincula tu cuenta para no perder tu progreso.';

  @override
  String get phoneVerifyEmailFallbackTitle => 'Verifica con tu correo';

  @override
  String get phoneVerifyEmailFallbackSubtitle =>
      'Los SMS no están disponibles para Indonesia (+62).\nTe enviaremos un código a tu correo.';

  @override
  String get phoneVerifyEmailFallbackLabel => 'Correo electrónico';

  @override
  String get phoneVerifyEmailFallbackHint => 'tucorreo@email.com';

  @override
  String phoneVerifyEmailFallbackSent(String email) {
    return 'Código enviado a $email';
  }

  @override
  String get phoneVerifyEmailFallbackInvalid => 'Ingresa un correo válido';

  @override
  String get phoneVerifyButtonSendEmail => 'Enviar código al correo';

  @override
  String get profileMadeByTeam => 'App desarrollada por el equipo de Juegalo';
}
