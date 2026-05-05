import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @tutorialWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a JUEGALO!'**
  String get tutorialWelcomeTitle;

  /// No description provided for @tutorialWelcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La app donde juegas, haces\nencuestas y ganas dinero real.'**
  String get tutorialWelcomeSubtitle;

  /// No description provided for @tutorialWelcomeFree.
  ///
  /// In es, this message translates to:
  /// **'100% gratis para siempre'**
  String get tutorialWelcomeFree;

  /// No description provided for @tutorialWelcomeFreeValue.
  ///
  /// In es, this message translates to:
  /// **'Sin cargos'**
  String get tutorialWelcomeFreeValue;

  /// No description provided for @tutorialWelcomeLatam.
  ///
  /// In es, this message translates to:
  /// **'Disponible en Latinoamérica'**
  String get tutorialWelcomeLatam;

  /// No description provided for @tutorialWelcomeLatamValue.
  ///
  /// In es, this message translates to:
  /// **'Desde hoy'**
  String get tutorialWelcomeLatamValue;

  /// No description provided for @tutorialWelcomeStart.
  ///
  /// In es, this message translates to:
  /// **'Empieza a ganar en 1 minuto'**
  String get tutorialWelcomeStart;

  /// No description provided for @tutorialWelcomeStartValue.
  ///
  /// In es, this message translates to:
  /// **'Rápido'**
  String get tutorialWelcomeStartValue;

  /// No description provided for @tutorialEarnTitle.
  ///
  /// In es, this message translates to:
  /// **'Gana monedas fácil'**
  String get tutorialEarnTitle;

  /// No description provided for @tutorialEarnSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tres formas de acumular\nmonedas cada día.'**
  String get tutorialEarnSubtitle;

  /// No description provided for @tutorialEarnVideos.
  ///
  /// In es, this message translates to:
  /// **'Videos cortos'**
  String get tutorialEarnVideos;

  /// No description provided for @tutorialEarnVideosValue.
  ///
  /// In es, this message translates to:
  /// **'+50 monedas c/u'**
  String get tutorialEarnVideosValue;

  /// No description provided for @tutorialEarnSurveys.
  ///
  /// In es, this message translates to:
  /// **'Encuestas'**
  String get tutorialEarnSurveys;

  /// No description provided for @tutorialEarnSurveysValue.
  ///
  /// In es, this message translates to:
  /// **'hasta 500 monedas'**
  String get tutorialEarnSurveysValue;

  /// No description provided for @tutorialEarnGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos'**
  String get tutorialEarnGames;

  /// No description provided for @tutorialEarnGamesValue.
  ///
  /// In es, this message translates to:
  /// **'hasta 2,000 monedas'**
  String get tutorialEarnGamesValue;

  /// No description provided for @tutorialRankingTitle.
  ///
  /// In es, this message translates to:
  /// **'Ranking semanal'**
  String get tutorialRankingTitle;

  /// No description provided for @tutorialRankingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Compite cada semana.\nLos mejores ganan premios extra.'**
  String get tutorialRankingSubtitle;

  /// No description provided for @tutorialRankingFirst.
  ///
  /// In es, this message translates to:
  /// **'Puesto #1'**
  String get tutorialRankingFirst;

  /// No description provided for @tutorialRankingFirstValue.
  ///
  /// In es, this message translates to:
  /// **'2,500 monedas'**
  String get tutorialRankingFirstValue;

  /// No description provided for @tutorialRankingSecond.
  ///
  /// In es, this message translates to:
  /// **'Puesto #2'**
  String get tutorialRankingSecond;

  /// No description provided for @tutorialRankingSecondValue.
  ///
  /// In es, this message translates to:
  /// **'1,000 monedas'**
  String get tutorialRankingSecondValue;

  /// No description provided for @tutorialRankingThird.
  ///
  /// In es, this message translates to:
  /// **'Puesto #3'**
  String get tutorialRankingThird;

  /// No description provided for @tutorialRankingThirdValue.
  ///
  /// In es, this message translates to:
  /// **'500 monedas'**
  String get tutorialRankingThirdValue;

  /// No description provided for @tutorialCashoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Cobra cuando quieras'**
  String get tutorialCashoutTitle;

  /// No description provided for @tutorialCashoutSubtitle.
  ///
  /// In es, this message translates to:
  /// **'10,000 monedas = \$1.00 USD.\nRetira desde \$1 sin comisión.'**
  String get tutorialCashoutSubtitle;

  /// No description provided for @tutorialCashoutPaypalValue.
  ///
  /// In es, this message translates to:
  /// **'Instantáneo'**
  String get tutorialCashoutPaypalValue;

  /// No description provided for @tutorialSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get tutorialSkip;

  /// No description provided for @tutorialNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get tutorialNext;

  /// No description provided for @tutorialStartEarning.
  ///
  /// In es, this message translates to:
  /// **'¡Empezar a ganar!'**
  String get tutorialStartEarning;

  /// No description provided for @onboardingTagline.
  ///
  /// In es, this message translates to:
  /// **'Juega. Gana. Cobra.'**
  String get onboardingTagline;

  /// No description provided for @onboardingPaidBadge.
  ///
  /// In es, this message translates to:
  /// **'+\$12,847 pagados'**
  String get onboardingPaidBadge;

  /// No description provided for @onboardingHowItWorks.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo funciona?'**
  String get onboardingHowItWorks;

  /// No description provided for @onboardingFeaturePlay.
  ///
  /// In es, this message translates to:
  /// **'Juega'**
  String get onboardingFeaturePlay;

  /// No description provided for @onboardingFeaturePlaySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Instala juegos gratis y acumula monedas'**
  String get onboardingFeaturePlaySubtitle;

  /// No description provided for @onboardingFeatureSurveys.
  ///
  /// In es, this message translates to:
  /// **'Encuestas'**
  String get onboardingFeatureSurveys;

  /// No description provided for @onboardingFeatureSurveysSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gana monedas por cada encuesta completada'**
  String get onboardingFeatureSurveysSubtitle;

  /// No description provided for @onboardingFeatureCashout.
  ///
  /// In es, this message translates to:
  /// **'Cobra'**
  String get onboardingFeatureCashout;

  /// No description provided for @onboardingFeatureCashoutSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Retira a PayPal desde \$1 USD'**
  String get onboardingFeatureCashoutSubtitle;

  /// No description provided for @onboardingStartNow.
  ///
  /// In es, this message translates to:
  /// **'Empieza ahora'**
  String get onboardingStartNow;

  /// No description provided for @onboardingContinueGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get onboardingContinueGoogle;

  /// No description provided for @onboardingContinueApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get onboardingContinueApple;

  /// No description provided for @onboardingContinueEmail.
  ///
  /// In es, this message translates to:
  /// **'Continuar con correo'**
  String get onboardingContinueEmail;

  /// No description provided for @onboardingPlayGuest.
  ///
  /// In es, this message translates to:
  /// **'Jugar sin cuenta'**
  String get onboardingPlayGuest;

  /// No description provided for @onboardingLegal.
  ///
  /// In es, this message translates to:
  /// **'Al continuar aceptas los Términos de uso\ny la Política de privacidad'**
  String get onboardingLegal;

  /// No description provided for @onboardingOr.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get onboardingOr;

  /// No description provided for @onboardingErrorWrongCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get onboardingErrorWrongCredentials;

  /// No description provided for @onboardingErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al entrar: {msg}'**
  String onboardingErrorGeneric(String msg);

  /// No description provided for @emailDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get emailDialogTitle;

  /// No description provided for @emailDialogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Correo y contraseña'**
  String get emailDialogSubtitle;

  /// No description provided for @emailDialogEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailDialogEmail;

  /// No description provided for @emailDialogPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get emailDialogPassword;

  /// No description provided for @emailDialogSignIn.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get emailDialogSignIn;

  /// No description provided for @homeTabGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos'**
  String get homeTabGames;

  /// No description provided for @homeTabSurveys.
  ///
  /// In es, this message translates to:
  /// **'Encuestas'**
  String get homeTabSurveys;

  /// No description provided for @homeTabVideos.
  ///
  /// In es, this message translates to:
  /// **'Videos'**
  String get homeTabVideos;

  /// No description provided for @homeTabRanking.
  ///
  /// In es, this message translates to:
  /// **'Ranking'**
  String get homeTabRanking;

  /// No description provided for @homeTabWallet.
  ///
  /// In es, this message translates to:
  /// **'Cobrar'**
  String get homeTabWallet;

  /// No description provided for @balanceCardLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu saldo'**
  String get balanceCardLabel;

  /// No description provided for @balanceCardCoins.
  ///
  /// In es, this message translates to:
  /// **'{coins} monedas'**
  String balanceCardCoins(String coins);

  /// No description provided for @balanceCardCashout.
  ///
  /// In es, this message translates to:
  /// **'Cobrar'**
  String get balanceCardCashout;

  /// No description provided for @dailyBonusTitle.
  ///
  /// In es, this message translates to:
  /// **'Bono diario'**
  String get dailyBonusTitle;

  /// No description provided for @dailyBonusStreakZero.
  ///
  /// In es, this message translates to:
  /// **'Comienza tu racha hoy'**
  String get dailyBonusStreakZero;

  /// No description provided for @dailyBonusStreakOne.
  ///
  /// In es, this message translates to:
  /// **'{count} día seguido'**
  String dailyBonusStreakOne(int count);

  /// No description provided for @dailyBonusStreakMany.
  ///
  /// In es, this message translates to:
  /// **'{count} días seguidos'**
  String dailyBonusStreakMany(int count);

  /// No description provided for @dailyBonusDays.
  ///
  /// In es, this message translates to:
  /// **'{count} días'**
  String dailyBonusDays(int count);

  /// No description provided for @dailyBonusClaimed.
  ///
  /// In es, this message translates to:
  /// **'Reclamado hoy'**
  String get dailyBonusClaimed;

  /// No description provided for @dailyBonusTodayPrize.
  ///
  /// In es, this message translates to:
  /// **'Premio de hoy'**
  String get dailyBonusTodayPrize;

  /// No description provided for @dailyBonusCoins.
  ///
  /// In es, this message translates to:
  /// **'+{coins} monedas'**
  String dailyBonusCoins(String coins);

  /// No description provided for @dailyBonusNextMilestone.
  ///
  /// In es, this message translates to:
  /// **'Día {day} → +{coins} monedas'**
  String dailyBonusNextMilestone(int day, String coins);

  /// No description provided for @dailyBonusClaimedBadge.
  ///
  /// In es, this message translates to:
  /// **'Reclamado'**
  String get dailyBonusClaimedBadge;

  /// No description provided for @dailyBonusDayMon.
  ///
  /// In es, this message translates to:
  /// **'Lun'**
  String get dailyBonusDayMon;

  /// No description provided for @dailyBonusDayTue.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get dailyBonusDayTue;

  /// No description provided for @dailyBonusDayWed.
  ///
  /// In es, this message translates to:
  /// **'Mié'**
  String get dailyBonusDayWed;

  /// No description provided for @dailyBonusDayThu.
  ///
  /// In es, this message translates to:
  /// **'Jue'**
  String get dailyBonusDayThu;

  /// No description provided for @dailyBonusDayFri.
  ///
  /// In es, this message translates to:
  /// **'Vie'**
  String get dailyBonusDayFri;

  /// No description provided for @dailyBonusDaySat.
  ///
  /// In es, this message translates to:
  /// **'Sáb'**
  String get dailyBonusDaySat;

  /// No description provided for @dailyBonusDaySun.
  ///
  /// In es, this message translates to:
  /// **'Dom'**
  String get dailyBonusDaySun;

  /// No description provided for @dailyGoalReached.
  ///
  /// In es, this message translates to:
  /// **'¡Meta! +1,500 🎯'**
  String get dailyGoalReached;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In es, this message translates to:
  /// **'Meta de hoy'**
  String get dailyGoalLabel;

  /// No description provided for @dailyGoalRemaining.
  ///
  /// In es, this message translates to:
  /// **'Faltan {coins} monedas para el bono de 1,500 monedas gratis.'**
  String dailyGoalRemaining(String coins);

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get profileTitle;

  /// No description provided for @profileCurrentCoins.
  ///
  /// In es, this message translates to:
  /// **'Monedas actuales'**
  String get profileCurrentCoins;

  /// No description provided for @profileTotalEarned.
  ///
  /// In es, this message translates to:
  /// **'Total ganado (USD)'**
  String get profileTotalEarned;

  /// No description provided for @profileCurrentStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get profileCurrentStreak;

  /// No description provided for @profileStreakDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días'**
  String profileStreakDays(int days);

  /// No description provided for @profileSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileSignOut;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get profileDeleteAccount;

  /// No description provided for @profileIdCopied.
  ///
  /// In es, this message translates to:
  /// **'ID copiado al portapapeles'**
  String get profileIdCopied;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In es, this message translates to:
  /// **'¡Foto actualizada!'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoError.
  ///
  /// In es, this message translates to:
  /// **'Error al subir foto: {error}'**
  String profilePhotoError(String error);

  /// No description provided for @profileTakePhoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get profileTakePhoto;

  /// No description provided for @profileChooseGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de galería'**
  String get profileChooseGallery;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteContent.
  ///
  /// In es, this message translates to:
  /// **'Esta acción es irreversible.\n\nSe eliminarán tu perfil, historial y saldo de monedas. Las solicitudes de cobro pendientes se conservan 90 días por obligación legal.\n\n¿Estás seguro de que quieres continuar?'**
  String get profileDeleteContent;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Sí, eliminar'**
  String get profileDeleteConfirm;

  /// No description provided for @profileCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get profileCancel;

  /// No description provided for @profileConnectionError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Intenta de nuevo.'**
  String get profileConnectionError;

  /// No description provided for @profileVerifiedAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta verificada'**
  String get profileVerifiedAccount;

  /// No description provided for @profileNoEmail.
  ///
  /// In es, this message translates to:
  /// **'Sin correo registrado'**
  String get profileNoEmail;

  /// No description provided for @profileGuestTitle.
  ///
  /// In es, this message translates to:
  /// **'Estás como invitado'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vincula tu cuenta para no perder tus monedas'**
  String get profileGuestSubtitle;

  /// No description provided for @profileLinkGoogle.
  ///
  /// In es, this message translates to:
  /// **'Vincular con Google'**
  String get profileLinkGoogle;

  /// No description provided for @profileLinkApple.
  ///
  /// In es, this message translates to:
  /// **'Vincular con Apple'**
  String get profileLinkApple;

  /// No description provided for @profileLinkEmail.
  ///
  /// In es, this message translates to:
  /// **'Vincular con correo'**
  String get profileLinkEmail;

  /// No description provided for @profileCoinsPreserved.
  ///
  /// In es, this message translates to:
  /// **'Tus monedas se conservan al vincular tu cuenta.'**
  String get profileCoinsPreserved;

  /// No description provided for @profileLinkEmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Vincular con correo'**
  String get profileLinkEmailTitle;

  /// No description provided for @profileLinkEmailSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus monedas se conservan.'**
  String get profileLinkEmailSubtitle;

  /// No description provided for @profileConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get profileConfirmPassword;

  /// No description provided for @profileLinkSave.
  ///
  /// In es, this message translates to:
  /// **'Vincular y guardar monedas'**
  String get profileLinkSave;

  /// No description provided for @profilePasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get profilePasswordMismatch;

  /// No description provided for @profilePasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get profilePasswordTooShort;

  /// No description provided for @profileLinkedGoogle.
  ///
  /// In es, this message translates to:
  /// **'¡Cuenta vinculada con Google!'**
  String get profileLinkedGoogle;

  /// No description provided for @profileLinkedApple.
  ///
  /// In es, this message translates to:
  /// **'¡Cuenta vinculada con Apple!'**
  String get profileLinkedApple;

  /// No description provided for @profileLinkedEmail.
  ///
  /// In es, this message translates to:
  /// **'¡Cuenta creada! Tus monedas se conservaron.'**
  String get profileLinkedEmail;

  /// No description provided for @referralInviteFriends.
  ///
  /// In es, this message translates to:
  /// **'Invita amigos'**
  String get referralInviteFriends;

  /// No description provided for @referralBothEarn.
  ///
  /// In es, this message translates to:
  /// **'Ganan 1,000 monedas los dos'**
  String get referralBothEarn;

  /// No description provided for @referralYourCode.
  ///
  /// In es, this message translates to:
  /// **'Tu código'**
  String get referralYourCode;

  /// No description provided for @referralCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get referralCopy;

  /// No description provided for @referralShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir código'**
  String get referralShare;

  /// No description provided for @referralShareMessage.
  ///
  /// In es, this message translates to:
  /// **'¡Únete a JUEGALO y gana dinero real jugando, completando encuestas y viendo videos! 🎮💰\n\nUsa mi código al registrarte y los dos ganamos 1,000 monedas cuando hagas tu primer cobro.\n\n📱 Código: {code}\n\nDescarga la app: juegalo.app'**
  String referralShareMessage(String code);

  /// No description provided for @referralShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Gana dinero con JUEGALO'**
  String get referralShareSubject;

  /// No description provided for @referralCodeCopied.
  ///
  /// In es, this message translates to:
  /// **'Código copiado al portapapeles'**
  String get referralCodeCopied;

  /// No description provided for @referralBonusPaid.
  ///
  /// In es, this message translates to:
  /// **'Bono de referido recibido'**
  String get referralBonusPaid;

  /// No description provided for @referralBonusPending.
  ///
  /// In es, this message translates to:
  /// **'Bono pendiente'**
  String get referralBonusPending;

  /// No description provided for @referralBonusPaidDesc.
  ///
  /// In es, this message translates to:
  /// **'+1,000 monedas ya fueron agregadas a tu cuenta.'**
  String get referralBonusPaidDesc;

  /// No description provided for @referralBonusPendingDesc.
  ///
  /// In es, this message translates to:
  /// **'Recibirás 1,000 monedas al hacer tu primer cobro.'**
  String get referralBonusPendingDesc;

  /// No description provided for @referralRegisterCode.
  ///
  /// In es, this message translates to:
  /// **'¿Te invitó alguien? Registra su código'**
  String get referralRegisterCode;

  /// No description provided for @referralCount.
  ///
  /// In es, this message translates to:
  /// **'Referidos'**
  String get referralCount;

  /// No description provided for @referralEarnings.
  ///
  /// In es, this message translates to:
  /// **'Monedas ganadas'**
  String get referralEarnings;

  /// No description provided for @referralDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Te invitó alguien?'**
  String get referralDialogTitle;

  /// No description provided for @referralDialogSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código de tu amigo.'**
  String get referralDialogSubtitle;

  /// No description provided for @referralBothGet.
  ///
  /// In es, this message translates to:
  /// **'Los dos reciben 1,000 monedas cuando hagas tu primer cobro.'**
  String get referralBothGet;

  /// No description provided for @referralApplyCode.
  ///
  /// In es, this message translates to:
  /// **'Aplicar código'**
  String get referralApplyCode;

  /// No description provided for @referralHowTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo funciona el bono'**
  String get referralHowTitle;

  /// No description provided for @referralHowStep1.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el código de quien te invitó.'**
  String get referralHowStep1;

  /// No description provided for @referralHowStep2.
  ///
  /// In es, this message translates to:
  /// **'Tú y tu amigo reciben 1,000 monedas cada uno.'**
  String get referralHowStep2;

  /// No description provided for @referralHowStep3.
  ///
  /// In es, this message translates to:
  /// **'El bono se acredita cuando tú completes tu primer cobro exitoso.'**
  String get referralHowStep3;

  /// No description provided for @referralHowStep4.
  ///
  /// In es, this message translates to:
  /// **'Solo puedes registrar un código una vez y antes de tu primer cobro.'**
  String get referralHowStep4;

  /// No description provided for @referralHowGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get referralHowGotIt;

  /// No description provided for @referralRegistered.
  ///
  /// In es, this message translates to:
  /// **'🎁 ¡Código registrado! El bono (1,000 monedas c/u) se acredita cuando hagas tu primer cobro.'**
  String get referralRegistered;

  /// No description provided for @rankingTitle.
  ///
  /// In es, this message translates to:
  /// **'Ranking Semanal'**
  String get rankingTitle;

  /// No description provided for @rankingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Top jugadores de la semana'**
  String get rankingSubtitle;

  /// No description provided for @rankingResetsMonday.
  ///
  /// In es, this message translates to:
  /// **'Se reinicia cada lunes'**
  String get rankingResetsMonday;

  /// No description provided for @rankingBeFirst.
  ///
  /// In es, this message translates to:
  /// **'¡Sé el primero!'**
  String get rankingBeFirst;

  /// No description provided for @rankingEmptyDesc.
  ///
  /// In es, this message translates to:
  /// **'Nadie ha ganado monedas esta semana.\nEl ranking se llena conforme los jugadores compiten.'**
  String get rankingEmptyDesc;

  /// No description provided for @rankingMyPosition.
  ///
  /// In es, this message translates to:
  /// **'Tu posición actual'**
  String get rankingMyPosition;

  /// No description provided for @rankingEarnToClimb.
  ///
  /// In es, this message translates to:
  /// **'Gana monedas para subir'**
  String get rankingEarnToClimb;

  /// No description provided for @rankingTipGames.
  ///
  /// In es, this message translates to:
  /// **'Instala juegos y completa misiones'**
  String get rankingTipGames;

  /// No description provided for @rankingSurveysTip.
  ///
  /// In es, this message translates to:
  /// **'Completa encuestas y gana rápido'**
  String get rankingSurveysTip;

  /// No description provided for @rankingVideosTip.
  ///
  /// In es, this message translates to:
  /// **'Ve 20 videos diarios para acumular'**
  String get rankingVideosTip;

  /// No description provided for @rankingPositions.
  ///
  /// In es, this message translates to:
  /// **'POSICIONES 4 – {total}'**
  String rankingPositions(int total);

  /// No description provided for @rankingMyPositionBar.
  ///
  /// In es, this message translates to:
  /// **'Tu posición esta semana'**
  String get rankingMyPositionBar;

  /// No description provided for @rankingKeepPlaying.
  ///
  /// In es, this message translates to:
  /// **'¡Sigue jugando para subir!'**
  String get rankingKeepPlaying;

  /// No description provided for @rankingLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el ranking'**
  String get rankingLoadError;

  /// No description provided for @rankingRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get rankingRetry;

  /// No description provided for @rankingYou.
  ///
  /// In es, this message translates to:
  /// **'TÚ'**
  String get rankingYou;

  /// No description provided for @surveysTitle.
  ///
  /// In es, this message translates to:
  /// **'Encuestas disponibles'**
  String get surveysTitle;

  /// No description provided for @surveysUpdated.
  ///
  /// In es, this message translates to:
  /// **'Actualizado {time}'**
  String surveysUpdated(String time);

  /// No description provided for @surveysCount.
  ///
  /// In es, this message translates to:
  /// **'{count} encuesta • {time}'**
  String surveysCount(int count, String time);

  /// No description provided for @surveysCountPlural.
  ///
  /// In es, this message translates to:
  /// **'{count} encuestas • {time}'**
  String surveysCountPlural(int count, String time);

  /// No description provided for @surveysRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get surveysRefresh;

  /// No description provided for @surveysEarn.
  ///
  /// In es, this message translates to:
  /// **'Ganas '**
  String get surveysEarn;

  /// No description provided for @surveysPerSurvey.
  ///
  /// In es, this message translates to:
  /// **' por cada encuesta completada'**
  String get surveysPerSurvey;

  /// No description provided for @surveysEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay encuestas disponibles'**
  String get surveysEmpty;

  /// No description provided for @surveysEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Vuelve más tarde o toca actualizar'**
  String get surveysEmptySubtitle;

  /// No description provided for @surveysTimeAgoSeconds.
  ///
  /// In es, this message translates to:
  /// **'hace {sec}s'**
  String surveysTimeAgoSeconds(int sec);

  /// No description provided for @surveysTimeAgoMinutes.
  ///
  /// In es, this message translates to:
  /// **'hace {min} min'**
  String surveysTimeAgoMinutes(int min);

  /// No description provided for @surveysTimeAgoHours.
  ///
  /// In es, this message translates to:
  /// **'hace {hr}h'**
  String surveysTimeAgoHours(int hr);

  /// No description provided for @surveysCoinsEarned.
  ///
  /// In es, this message translates to:
  /// **'+{coins} monedas — encuesta completada'**
  String surveysCoinsEarned(String coins);

  /// No description provided for @videosTitle.
  ///
  /// In es, this message translates to:
  /// **'Videos disponibles'**
  String get videosTitle;

  /// No description provided for @videosTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'Videos de hoy'**
  String get videosTodayTitle;

  /// No description provided for @videosEarnedToday.
  ///
  /// In es, this message translates to:
  /// **'{coins} monedas ganadas hoy'**
  String videosEarnedToday(int coins);

  /// No description provided for @videosLimitReached.
  ///
  /// In es, this message translates to:
  /// **'Límite alcanzado'**
  String get videosLimitReached;

  /// No description provided for @videosRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get videosRetry;

  /// No description provided for @videosWatch.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get videosWatch;

  /// No description provided for @videosHowItWorks.
  ///
  /// In es, this message translates to:
  /// **'Cómo funciona'**
  String get videosHowItWorks;

  /// No description provided for @videosInfoFull.
  ///
  /// In es, this message translates to:
  /// **'Ve el anuncio completo para ganar monedas'**
  String get videosInfoFull;

  /// No description provided for @videosInfoLimit.
  ///
  /// In es, this message translates to:
  /// **'Límite de 50 anuncios por día'**
  String get videosInfoLimit;

  /// No description provided for @videosInfoCoins.
  ///
  /// In es, this message translates to:
  /// **'30 monedas por anuncio completado'**
  String get videosInfoCoins;

  /// No description provided for @videosInfoAccumulate.
  ///
  /// In es, this message translates to:
  /// **'Acumula 10,000 monedas para cobrar \$1.00'**
  String get videosInfoAccumulate;

  /// No description provided for @videosAvailabilityNote.
  ///
  /// In es, this message translates to:
  /// **'Los anuncios se cargan según disponibilidad. Si no aparecen, toca \"Reintentar\" en unos segundos.'**
  String get videosAvailabilityNote;

  /// No description provided for @videosCoinsEarned.
  ///
  /// In es, this message translates to:
  /// **'+{coins} monedas ganadas'**
  String videosCoinsEarned(int coins);

  /// No description provided for @videosErrorCredit.
  ///
  /// In es, this message translates to:
  /// **'Error al acreditar monedas: {error}'**
  String videosErrorCredit(String error);

  /// No description provided for @videosSlot.
  ///
  /// In es, this message translates to:
  /// **'Video {number}'**
  String videosSlot(int number);

  /// No description provided for @walletErrorLoading.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar'**
  String get walletErrorLoading;

  /// No description provided for @walletCoinsAvailable.
  ///
  /// In es, this message translates to:
  /// **'{coins} monedas disponibles'**
  String walletCoinsAvailable(String coins);

  /// No description provided for @walletRequestCashout.
  ///
  /// In es, this message translates to:
  /// **'Solicitar cobro'**
  String get walletRequestCashout;

  /// No description provided for @walletMinimumCashout.
  ///
  /// In es, this message translates to:
  /// **'Mínimo \$1.00 para retirar'**
  String get walletMinimumCashout;

  /// No description provided for @walletPaymentMethods.
  ///
  /// In es, this message translates to:
  /// **'Métodos de cobro'**
  String get walletPaymentMethods;

  /// No description provided for @walletPaypalDesc.
  ///
  /// In es, this message translates to:
  /// **'Internacional · 1–3 días hábiles'**
  String get walletPaypalDesc;

  /// No description provided for @walletMercadopagoDesc.
  ///
  /// In es, this message translates to:
  /// **'México y LatAm · sin comisión'**
  String get walletMercadopagoDesc;

  /// No description provided for @walletComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get walletComingSoon;

  /// No description provided for @walletComingSoonFull.
  ///
  /// In es, this message translates to:
  /// **'Próximamente disponible'**
  String get walletComingSoonFull;

  /// No description provided for @walletTransactions.
  ///
  /// In es, this message translates to:
  /// **'Últimas transacciones'**
  String get walletTransactions;

  /// No description provided for @walletNoTransactions.
  ///
  /// In es, this message translates to:
  /// **'Sin transacciones aún'**
  String get walletNoTransactions;

  /// No description provided for @walletAlmostThere.
  ///
  /// In es, this message translates to:
  /// **'¡Casi llegas!'**
  String get walletAlmostThere;

  /// No description provided for @walletNeedCoins.
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos {coins} monedas (\$1.00 USD) para retirar.\n\nTe faltan {missing} monedas.'**
  String walletNeedCoins(String coins, String missing);

  /// No description provided for @walletGotIt.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get walletGotIt;

  /// No description provided for @cashoutStepRequested.
  ///
  /// In es, this message translates to:
  /// **'Solicitado'**
  String get cashoutStepRequested;

  /// No description provided for @cashoutStepRequestedSub.
  ///
  /// In es, this message translates to:
  /// **'Recibimos tu solicitud'**
  String get cashoutStepRequestedSub;

  /// No description provided for @cashoutStepReview.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get cashoutStepReview;

  /// No description provided for @cashoutStepReviewSub.
  ///
  /// In es, this message translates to:
  /// **'Verificando los datos'**
  String get cashoutStepReviewSub;

  /// No description provided for @cashoutStepProcessing.
  ///
  /// In es, this message translates to:
  /// **'Procesando'**
  String get cashoutStepProcessing;

  /// No description provided for @cashoutStepProcessingSub.
  ///
  /// In es, this message translates to:
  /// **'Enviando el pago'**
  String get cashoutStepProcessingSub;

  /// No description provided for @cashoutStepPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get cashoutStepPaid;

  /// No description provided for @cashoutStepPaidSub.
  ///
  /// In es, this message translates to:
  /// **'¡Dinero enviado!'**
  String get cashoutStepPaidSub;

  /// No description provided for @cashoutStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get cashoutStatusPending;

  /// No description provided for @cashoutStatusProcessing.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get cashoutStatusProcessing;

  /// No description provided for @cashoutStatusPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get cashoutStatusPaid;

  /// No description provided for @cashoutStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get cashoutStatusRejected;

  /// No description provided for @cashoutRequestHeader.
  ///
  /// In es, this message translates to:
  /// **'Cobro de \${amount} USD · {method}'**
  String cashoutRequestHeader(String amount, String method);

  /// No description provided for @cashoutPaidBanner.
  ///
  /// In es, this message translates to:
  /// **'¡Tu pago fue enviado!'**
  String get cashoutPaidBanner;

  /// No description provided for @cashoutPaidBannerSub.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu cuenta de PayPal.'**
  String get cashoutPaidBannerSub;

  /// No description provided for @cashoutReferralBanner.
  ///
  /// In es, this message translates to:
  /// **'¡Código de referido cobrado!'**
  String get cashoutReferralBanner;

  /// No description provided for @cashoutReferralBannerSub.
  ///
  /// In es, this message translates to:
  /// **'Tú y tu amigo ya tienen sus 1,000 monedas.'**
  String get cashoutReferralBannerSub;

  /// No description provided for @cashoutTimePending.
  ///
  /// In es, this message translates to:
  /// **'Tiempo estimado: 1–3 días hábiles. Te avisaremos cuando sea enviado.'**
  String get cashoutTimePending;

  /// No description provided for @cashoutTimeProcessing.
  ///
  /// In es, this message translates to:
  /// **'Tu pago está siendo procesado. Llegará pronto a tu cuenta.'**
  String get cashoutTimeProcessing;

  /// No description provided for @cashoutPaidOn.
  ///
  /// In es, this message translates to:
  /// **'Pagado el {date} a las {time}'**
  String cashoutPaidOn(String date, String time);

  /// No description provided for @cashoutRequestedOn.
  ///
  /// In es, this message translates to:
  /// **'Solicitado el {date} a las {time}'**
  String cashoutRequestedOn(String date, String time);

  /// No description provided for @cashoutAppTitle.
  ///
  /// In es, this message translates to:
  /// **'Solicitar cobro'**
  String get cashoutAppTitle;

  /// No description provided for @cashoutAmountTitle.
  ///
  /// In es, this message translates to:
  /// **'Monto a cobrar'**
  String get cashoutAmountTitle;

  /// No description provided for @cashoutMethodTitle.
  ///
  /// In es, this message translates to:
  /// **'Método de cobro'**
  String get cashoutMethodTitle;

  /// No description provided for @cashoutAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de tu cuenta'**
  String get cashoutAccountTitle;

  /// No description provided for @cashoutSummaryAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get cashoutSummaryAmount;

  /// No description provided for @cashoutSummaryCoins.
  ///
  /// In es, this message translates to:
  /// **'Monedas a descontar'**
  String get cashoutSummaryCoins;

  /// No description provided for @cashoutSummaryMethod.
  ///
  /// In es, this message translates to:
  /// **'Método'**
  String get cashoutSummaryMethod;

  /// No description provided for @cashoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar cobro de \${amount}'**
  String cashoutConfirm(String amount);

  /// No description provided for @cashoutProcessingNote.
  ///
  /// In es, this message translates to:
  /// **'Procesamos tu pago en 1–3 días hábiles'**
  String get cashoutProcessingNote;

  /// No description provided for @cashoutEnterAccount.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los datos de tu cuenta'**
  String get cashoutEnterAccount;

  /// No description provided for @cashoutSentSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Solicitud enviada! Procesamos en 1-3 días hábiles'**
  String get cashoutSentSuccess;

  /// No description provided for @cashoutUsdAvailable.
  ///
  /// In es, this message translates to:
  /// **'\${usd} USD disponibles'**
  String cashoutUsdAvailable(String usd);

  /// No description provided for @cashoutCoins.
  ///
  /// In es, this message translates to:
  /// **'{coins} monedas'**
  String cashoutCoins(String coins);

  /// No description provided for @cashoutNeedCoins.
  ///
  /// In es, this message translates to:
  /// **'Necesitas al menos {coins} monedas (\$1.00 USD) para retirar por PayPal.\n\nTe faltan {missing} monedas.'**
  String cashoutNeedCoins(String coins, String missing);

  /// No description provided for @cashoutGuestTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea una cuenta para cobrar'**
  String get cashoutGuestTitle;

  /// No description provided for @cashoutGuestSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Estás jugando como invitado. Vincula tu cuenta\ny conserva todas las monedas que ganaste.'**
  String get cashoutGuestSubtitle;

  /// No description provided for @cashoutGuestCurrentCoins.
  ///
  /// In es, this message translates to:
  /// **'Tus monedas actuales'**
  String get cashoutGuestCurrentCoins;

  /// No description provided for @cashoutGuestCoins.
  ///
  /// In es, this message translates to:
  /// **'{coins} monedas'**
  String cashoutGuestCoins(String coins);

  /// No description provided for @cashoutGuestContinueGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get cashoutGuestContinueGoogle;

  /// No description provided for @cashoutGuestContinueApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get cashoutGuestContinueApple;

  /// No description provided for @cashoutGuestCreateEmail.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta con correo'**
  String get cashoutGuestCreateEmail;

  /// No description provided for @cashoutGuestNote.
  ///
  /// In es, this message translates to:
  /// **'Tus monedas se transferirán automáticamente\na tu cuenta nueva.'**
  String get cashoutGuestNote;

  /// No description provided for @cashoutGuestLinked.
  ///
  /// In es, this message translates to:
  /// **'¡Cuenta vinculada! Tus monedas se conservaron.'**
  String get cashoutGuestLinked;

  /// No description provided for @cashoutGuestCreated.
  ///
  /// In es, this message translates to:
  /// **'¡Cuenta creada! Tus monedas se conservaron.'**
  String get cashoutGuestCreated;

  /// No description provided for @profileFirstName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profileFirstName;

  /// No description provided for @profileLastName.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get profileLastName;

  /// No description provided for @cashoutMinLabel.
  ///
  /// In es, this message translates to:
  /// **'{usd} mín'**
  String cashoutMinLabel(String usd);

  /// No description provided for @cashoutMaxLabel.
  ///
  /// In es, this message translates to:
  /// **'{usd} máx'**
  String cashoutMaxLabel(String usd);

  /// No description provided for @cashoutGuestLinkedErrorGoogle.
  ///
  /// In es, this message translates to:
  /// **'Error al vincular con Google: {error}'**
  String cashoutGuestLinkedErrorGoogle(String error);

  /// No description provided for @cashoutGuestLinkedErrorApple.
  ///
  /// In es, this message translates to:
  /// **'Error al vincular con Apple: {error}'**
  String cashoutGuestLinkedErrorApple(String error);

  /// No description provided for @cashoutCreateEmailTitle.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta con correo'**
  String get cashoutCreateEmailTitle;

  /// No description provided for @cashoutCreateEmailSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tus monedas se conservarán automáticamente.'**
  String get cashoutCreateEmailSubtitle;

  /// No description provided for @cashoutCreateEmailButton.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta y conservar monedas'**
  String get cashoutCreateEmailButton;

  /// No description provided for @cashoutPasswordMismatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get cashoutPasswordMismatch;

  /// No description provided for @cashoutPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres'**
  String get cashoutPasswordTooShort;

  /// No description provided for @cashoutPaypalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Internacional · procesamos en 1–3 días hábiles'**
  String get cashoutPaypalSubtitle;

  /// No description provided for @cashoutMercadopagoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Próximamente disponible'**
  String get cashoutMercadopagoSubtitle;

  /// No description provided for @gamesTitle.
  ///
  /// In es, this message translates to:
  /// **'Ofertas y Juegos'**
  String get gamesTitle;

  /// No description provided for @gamesAvailable.
  ///
  /// In es, this message translates to:
  /// **'🎮 ¡Ya disponible!'**
  String get gamesAvailable;

  /// No description provided for @gamesSoon.
  ///
  /// In es, this message translates to:
  /// **'🚀 Próximamente'**
  String get gamesSoon;

  /// No description provided for @gamesDescription.
  ///
  /// In es, this message translates to:
  /// **'Instala juegos y apps para ganar\nmonedas extra sin ver anuncios.'**
  String get gamesDescription;

  /// No description provided for @gamesOpenButton.
  ///
  /// In es, this message translates to:
  /// **'Ver juegos y ofertas'**
  String get gamesOpenButton;

  /// No description provided for @gamesExploreSoon.
  ///
  /// In es, this message translates to:
  /// **'Explorar próximamente'**
  String get gamesExploreSoon;

  /// No description provided for @gamesInstallGames.
  ///
  /// In es, this message translates to:
  /// **'Instala juegos'**
  String get gamesInstallGames;

  /// No description provided for @gamesInstallGamesDesc.
  ///
  /// In es, this message translates to:
  /// **'Gana monedas por instalar y jugar nuevos juegos.'**
  String get gamesInstallGamesDesc;

  /// No description provided for @gamesDownloadApps.
  ///
  /// In es, this message translates to:
  /// **'Descarga apps'**
  String get gamesDownloadApps;

  /// No description provided for @gamesDownloadAppsDesc.
  ///
  /// In es, this message translates to:
  /// **'Completa tareas en apps y recibe monedas al instante.'**
  String get gamesDownloadAppsDesc;

  /// No description provided for @gamesCompleteMissions.
  ///
  /// In es, this message translates to:
  /// **'Completa misiones'**
  String get gamesCompleteMissions;

  /// No description provided for @gamesCompleteMissionsDesc.
  ///
  /// In es, this message translates to:
  /// **'Llega a un nivel específico en un juego y gana mucho más.'**
  String get gamesCompleteMissionsDesc;

  /// No description provided for @gamesOpenCatalog.
  ///
  /// In es, this message translates to:
  /// **'Toca el botón de arriba para ver el catálogo completo de juegos y ofertas.'**
  String get gamesOpenCatalog;

  /// No description provided for @gamesComingNotify.
  ///
  /// In es, this message translates to:
  /// **'Te avisaremos cuando esta sección esté disponible.'**
  String get gamesComingNotify;

  /// No description provided for @gamesOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el catálogo. Inténtalo de nuevo.'**
  String get gamesOpenError;

  /// No description provided for @gamesComingSoonTitle.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get gamesComingSoonTitle;

  /// No description provided for @gamesComingSoonContent.
  ///
  /// In es, this message translates to:
  /// **'Esta sección estará disponible muy pronto.\n¡Te avisaremos cuando puedas ganar monedas instalando juegos!'**
  String get gamesComingSoonContent;

  /// No description provided for @gamesComingSoonButton.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get gamesComingSoonButton;

  /// No description provided for @dailyBonusClaimedToast.
  ///
  /// In es, this message translates to:
  /// **'¡Bono diario reclamado!'**
  String get dailyBonusClaimedToast;

  /// No description provided for @dailyBonusCoinsAndStreak.
  ///
  /// In es, this message translates to:
  /// **'+{coins} monedas • Racha de {streak} {streakLabel}'**
  String dailyBonusCoinsAndStreak(int coins, int streak, String streakLabel);

  /// No description provided for @dailyBonusStreakLabelOne.
  ///
  /// In es, this message translates to:
  /// **'día'**
  String get dailyBonusStreakLabelOne;

  /// No description provided for @dailyBonusStreakLabelMany.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get dailyBonusStreakLabelMany;

  /// No description provided for @dailyGoalReachedToast.
  ///
  /// In es, this message translates to:
  /// **'¡Meta diaria alcanzada!'**
  String get dailyGoalReachedToast;

  /// No description provided for @dailyGoalBonusCoins.
  ///
  /// In es, this message translates to:
  /// **'+{coins} monedas de bono'**
  String dailyGoalBonusCoins(String coins);

  /// No description provided for @profileEditNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar nombre'**
  String get profileEditNameTitle;

  /// No description provided for @profileEditNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get profileEditNameHint;

  /// No description provided for @profileSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get profileSave;

  /// No description provided for @profileNameUpdated.
  ///
  /// In es, this message translates to:
  /// **'✅ Nombre actualizado'**
  String get profileNameUpdated;

  /// No description provided for @profileLanguageTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get profileLanguageTitle;

  /// No description provided for @profileLanguageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Español / English / Português'**
  String get profileLanguageSubtitle;

  /// No description provided for @profileLanguageDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el idioma'**
  String get profileLanguageDialogTitle;

  /// No description provided for @profileLanguageEs.
  ///
  /// In es, this message translates to:
  /// **'🇲🇽  Español'**
  String get profileLanguageEs;

  /// No description provided for @profileLanguageEn.
  ///
  /// In es, this message translates to:
  /// **'🇺🇸  English'**
  String get profileLanguageEn;

  /// No description provided for @profileLanguagePt.
  ///
  /// In es, this message translates to:
  /// **'🇧🇷  Português'**
  String get profileLanguagePt;

  /// No description provided for @profileLanguageAuto.
  ///
  /// In es, this message translates to:
  /// **'Automático (dispositivo)'**
  String get profileLanguageAuto;

  /// No description provided for @versionUpdateTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Actualización requerida!'**
  String get versionUpdateTitle;

  /// No description provided for @versionUpdateBody.
  ///
  /// In es, this message translates to:
  /// **'Para seguir ganando dinero con JUEGALO necesitas instalar la última versión. ¡Trae mejoras y más formas de ganar!'**
  String get versionUpdateBody;

  /// No description provided for @versionUpdateButton.
  ///
  /// In es, this message translates to:
  /// **'Actualizar ahora'**
  String get versionUpdateButton;

  /// No description provided for @versionUpdateNote.
  ///
  /// In es, this message translates to:
  /// **'La actualización es gratuita y solo toma unos segundos.'**
  String get versionUpdateNote;

  /// No description provided for @versionNewAvailable.
  ///
  /// In es, this message translates to:
  /// **'🚀 Nueva versión disponible'**
  String get versionNewAvailable;

  /// No description provided for @rankingPos1.
  ///
  /// In es, this message translates to:
  /// **'Puesto #1'**
  String get rankingPos1;

  /// No description provided for @rankingPos2.
  ///
  /// In es, this message translates to:
  /// **'Puesto #2'**
  String get rankingPos2;

  /// No description provided for @rankingPos3.
  ///
  /// In es, this message translates to:
  /// **'Puesto #3'**
  String get rankingPos3;

  /// No description provided for @rankingTop50.
  ///
  /// In es, this message translates to:
  /// **'TOP 50'**
  String get rankingTop50;

  /// No description provided for @rankingTop3Label.
  ///
  /// In es, this message translates to:
  /// **'TOP 3'**
  String get rankingTop3Label;

  /// No description provided for @rankingThisWeek.
  ///
  /// In es, this message translates to:
  /// **'esta semana'**
  String get rankingThisWeek;

  /// No description provided for @rankingStreakDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días consecutivos'**
  String rankingStreakDays(int days);

  /// No description provided for @rankingCelebFirst.
  ///
  /// In es, this message translates to:
  /// **'¡Primer lugar!'**
  String get rankingCelebFirst;

  /// No description provided for @rankingCelebSecond.
  ///
  /// In es, this message translates to:
  /// **'¡Segundo lugar!'**
  String get rankingCelebSecond;

  /// No description provided for @rankingCelebThird.
  ///
  /// In es, this message translates to:
  /// **'¡Tercer lugar!'**
  String get rankingCelebThird;

  /// No description provided for @rankingCelebSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La semana pasada fuiste uno\nde los mejores jugadores.'**
  String get rankingCelebSubtitle;

  /// No description provided for @rankingCelebCoinsLabel.
  ///
  /// In es, this message translates to:
  /// **'monedas acreditadas'**
  String get rankingCelebCoinsLabel;

  /// No description provided for @rankingCelebButton.
  ///
  /// In es, this message translates to:
  /// **'¡Genial! 🎉'**
  String get rankingCelebButton;

  /// No description provided for @rankingInfoTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo funciona el ranking?'**
  String get rankingInfoTitle;

  /// No description provided for @rankingInfoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sé de los mejores jugadores de la semana\ny obtén recompensas en monedas.'**
  String get rankingInfoSubtitle;

  /// No description provided for @rankingInfoFirst.
  ///
  /// In es, this message translates to:
  /// **'Primer lugar'**
  String get rankingInfoFirst;

  /// No description provided for @rankingInfoFirstDesc.
  ///
  /// In es, this message translates to:
  /// **'El jugador con más monedas acumuladas en la semana gana'**
  String get rankingInfoFirstDesc;

  /// No description provided for @rankingInfoSecond.
  ///
  /// In es, this message translates to:
  /// **'Segundo lugar'**
  String get rankingInfoSecond;

  /// No description provided for @rankingInfoSecondDesc.
  ///
  /// In es, this message translates to:
  /// **'Segundo puesto al cierre semanal gana'**
  String get rankingInfoSecondDesc;

  /// No description provided for @rankingInfoThird.
  ///
  /// In es, this message translates to:
  /// **'Tercer lugar'**
  String get rankingInfoThird;

  /// No description provided for @rankingInfoThirdDesc.
  ///
  /// In es, this message translates to:
  /// **'Tercer puesto al cierre semanal gana'**
  String get rankingInfoThirdDesc;

  /// No description provided for @rankingInfoHowToEarn.
  ///
  /// In es, this message translates to:
  /// **'💡 ¿Cómo acumular monedas?'**
  String get rankingInfoHowToEarn;

  /// No description provided for @rankingInfoTipGames.
  ///
  /// In es, this message translates to:
  /// **'Instala juegos y completa misiones'**
  String get rankingInfoTipGames;

  /// No description provided for @rankingInfoTipSurveys.
  ///
  /// In es, this message translates to:
  /// **'Completa encuestas diarias'**
  String get rankingInfoTipSurveys;

  /// No description provided for @rankingInfoTipVideos.
  ///
  /// In es, this message translates to:
  /// **'Ve hasta 20 videos al día'**
  String get rankingInfoTipVideos;

  /// No description provided for @rankingInfoTipStreak.
  ///
  /// In es, this message translates to:
  /// **'Mantén tu racha diaria para bonos extra'**
  String get rankingInfoTipStreak;

  /// No description provided for @rankingInfoGotIt.
  ///
  /// In es, this message translates to:
  /// **'¡Entendido!'**
  String get rankingInfoGotIt;

  /// No description provided for @rankingLastWinnersTitle.
  ///
  /// In es, this message translates to:
  /// **'🏆  GANADORES DE LA SEMANA PASADA'**
  String get rankingLastWinnersTitle;

  /// No description provided for @rankingLastWinnersPrize.
  ///
  /// In es, this message translates to:
  /// **'premio'**
  String get rankingLastWinnersPrize;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
