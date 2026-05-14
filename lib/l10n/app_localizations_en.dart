// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tutorialWelcomeTitle => 'Welcome to JUEGALO!';

  @override
  String get tutorialWelcomeSubtitle =>
      'The app where you play, take\nsurveys and earn real money.';

  @override
  String get tutorialWelcomeFree => '100% free forever';

  @override
  String get tutorialWelcomeFreeValue => 'No charges';

  @override
  String get tutorialWelcomeLatam => 'Available in Latin America';

  @override
  String get tutorialWelcomeLatamValue => 'Starting today';

  @override
  String get tutorialWelcomeStart => 'Start earning in 1 minute';

  @override
  String get tutorialWelcomeStartValue => 'Fast';

  @override
  String get tutorialEarnTitle => 'Earn coins easily';

  @override
  String get tutorialEarnSubtitle =>
      'Three ways to accumulate\ncoins every day.';

  @override
  String get tutorialEarnVideos => 'Short videos';

  @override
  String get tutorialEarnVideosValue => '+50 coins each';

  @override
  String get tutorialEarnSurveys => 'Surveys';

  @override
  String get tutorialEarnSurveysValue => 'up to 500 coins';

  @override
  String get tutorialEarnGames => 'Games';

  @override
  String get tutorialEarnGamesValue => 'up to 2,000 coins';

  @override
  String get tutorialRankingTitle => 'Weekly Ranking';

  @override
  String get tutorialRankingSubtitle =>
      'Compete every week.\nTop players win extra prizes.';

  @override
  String get tutorialRankingFirst => 'Place #1';

  @override
  String get tutorialRankingFirstValue => '2,500 coins';

  @override
  String get tutorialRankingSecond => 'Place #2';

  @override
  String get tutorialRankingSecondValue => '1,000 coins';

  @override
  String get tutorialRankingThird => 'Place #3';

  @override
  String get tutorialRankingThirdValue => '500 coins';

  @override
  String get tutorialCashoutTitle => 'Cash out anytime';

  @override
  String get tutorialCashoutSubtitle =>
      '10,000 coins = \$1.00 USD.\nWithdraw from \$1 with no fee.';

  @override
  String get tutorialCashoutPaypalValue => 'Instant';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialStartEarning => 'Start earning!';

  @override
  String get onboardingTagline => 'Play. Earn. Cash out.';

  @override
  String get onboardingPaidBadge => '+\$12,847 paid';

  @override
  String get onboardingHowItWorks => 'How does it work?';

  @override
  String get onboardingFeaturePlay => 'Play';

  @override
  String get onboardingFeaturePlaySubtitle =>
      'Install free games and accumulate coins';

  @override
  String get onboardingFeatureSurveys => 'Surveys';

  @override
  String get onboardingFeatureSurveysSubtitle =>
      'Earn coins for each completed survey';

  @override
  String get onboardingFeatureCashout => 'Cash out';

  @override
  String get onboardingFeatureCashoutSubtitle =>
      'Withdraw to PayPal from \$1 USD';

  @override
  String get onboardingStartNow => 'Get started now';

  @override
  String get onboardingContinueGoogle => 'Continue with Google';

  @override
  String get onboardingContinueApple => 'Continue with Apple';

  @override
  String get onboardingContinueEmail => 'Continue with email';

  @override
  String get onboardingPlayGuest => 'Play as guest';

  @override
  String get onboardingLegal =>
      'By continuing you agree to the Terms of Use\nand Privacy Policy';

  @override
  String get onboardingOr => 'or';

  @override
  String get onboardingErrorWrongCredentials => 'Wrong email or password';

  @override
  String onboardingErrorGeneric(String msg) {
    return 'Error signing in: $msg';
  }

  @override
  String get emailDialogTitle => 'Sign in';

  @override
  String get emailDialogSubtitle => 'Email and password';

  @override
  String get emailDialogEmail => 'Email address';

  @override
  String get emailDialogPassword => 'Password';

  @override
  String get emailDialogSignIn => 'Sign in';

  @override
  String get homeTabGames => 'Games';

  @override
  String get homeTabSurveys => 'Surveys';

  @override
  String get homeTabVideos => 'Videos';

  @override
  String get homeTabRanking => 'Ranking';

  @override
  String get homeTabWallet => 'Wallet';

  @override
  String get balanceCardLabel => 'Your balance';

  @override
  String balanceCardCoins(String coins) {
    return '$coins coins';
  }

  @override
  String get balanceCardCashout => 'Cash out';

  @override
  String get dailyBonusTitle => 'Daily bonus';

  @override
  String get dailyBonusStreakZero => 'Start your streak today';

  @override
  String dailyBonusStreakOne(int count) {
    return '$count day in a row';
  }

  @override
  String dailyBonusStreakMany(int count) {
    return '$count days in a row';
  }

  @override
  String dailyBonusDays(int count) {
    return '$count days';
  }

  @override
  String get dailyBonusClaimed => 'Claimed today';

  @override
  String get dailyBonusTodayPrize => 'Today\'s prize';

  @override
  String dailyBonusCoins(String coins) {
    return '+$coins coins';
  }

  @override
  String dailyBonusNextMilestone(int day, String coins) {
    return 'Day $day → +$coins coins';
  }

  @override
  String get dailyBonusClaimedBadge => 'Claimed';

  @override
  String get dailyBonusDayMon => 'Mon';

  @override
  String get dailyBonusDayTue => 'Tue';

  @override
  String get dailyBonusDayWed => 'Wed';

  @override
  String get dailyBonusDayThu => 'Thu';

  @override
  String get dailyBonusDayFri => 'Fri';

  @override
  String get dailyBonusDaySat => 'Sat';

  @override
  String get dailyBonusDaySun => 'Sun';

  @override
  String get dailyGoalReached => 'Goal! +1,500 🎯';

  @override
  String get dailyGoalLabel => 'Today\'s goal';

  @override
  String dailyGoalRemaining(String coins) {
    return 'Need $coins more coins for the 1,500 free coins bonus.';
  }

  @override
  String get profileTitle => 'My profile';

  @override
  String get profileCurrentCoins => 'Current coins';

  @override
  String get profileTotalEarned => 'Total earned (USD)';

  @override
  String get profileCurrentStreak => 'Current streak';

  @override
  String profileStreakDays(int days) {
    return '$days days';
  }

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileDeleteAccount => 'Delete my account';

  @override
  String get profileIdCopied => 'ID copied to clipboard';

  @override
  String get profilePhotoUpdated => 'Photo updated!';

  @override
  String profilePhotoError(String error) {
    return 'Error uploading photo: $error';
  }

  @override
  String get profileTakePhoto => 'Take photo';

  @override
  String get profileChooseGallery => 'Choose from gallery';

  @override
  String get profileDeleteTitle => 'Delete account';

  @override
  String get profileDeleteContent =>
      'This action is irreversible.\n\nYour profile, history and coin balance will be deleted. Pending cashout requests are kept for 90 days by legal obligation.\n\nAre you sure you want to continue?';

  @override
  String get profileDeleteConfirm => 'Yes, delete';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileConnectionError => 'Connection error. Please try again.';

  @override
  String get profileVerifiedAccount => 'Verified account';

  @override
  String get profileNoEmail => 'No email registered';

  @override
  String get profileGuestTitle => 'You\'re a guest';

  @override
  String get profileGuestSubtitle => 'Link your account to keep your coins';

  @override
  String get profileLinkGoogle => 'Link with Google';

  @override
  String get profileLinkApple => 'Link with Apple';

  @override
  String get profileLinkEmail => 'Link with email';

  @override
  String get profileCoinsPreserved =>
      'Your coins are preserved when you link your account.';

  @override
  String get profileLinkEmailTitle => 'Link with email';

  @override
  String get profileLinkEmailSubtitle => 'Your coins will be preserved.';

  @override
  String get profileConfirmPassword => 'Confirm password';

  @override
  String get profileLinkSave => 'Link and save coins';

  @override
  String get profilePasswordMismatch => 'Passwords do not match';

  @override
  String get profilePasswordTooShort => 'Minimum 6 characters';

  @override
  String get profileLinkedGoogle => 'Account linked with Google!';

  @override
  String get profileLinkedApple => 'Account linked with Apple!';

  @override
  String get profileLinkedEmail =>
      'Account created! Your coins were preserved.';

  @override
  String get referralInviteFriends => 'Invite friends';

  @override
  String get referralBothEarn => 'Both of you earn 1,000 coins';

  @override
  String get referralYourCode => 'Your code';

  @override
  String get referralCopy => 'Copy';

  @override
  String get referralShare => 'Share code';

  @override
  String referralShareMessage(String code) {
    return 'Join JUEGALO and earn real money playing, completing surveys and watching videos! 🎮💰\n\nUse my code when signing up and we both earn 1,000 coins when you make your first cashout.\n\n📱 Code: $code\n\nDownload the app: juegalo.app';
  }

  @override
  String get referralShareSubject => 'Earn money with JUEGALO';

  @override
  String get referralCodeCopied => 'Code copied to clipboard';

  @override
  String get referralBonusPaid => 'Referral bonus received';

  @override
  String get referralBonusPending => 'Bonus pending';

  @override
  String get referralBonusPaidDesc =>
      '+1,000 coins have been added to your account.';

  @override
  String get referralBonusPendingDesc =>
      'You\'ll receive 1,000 coins when you make your first cashout.';

  @override
  String get referralRegisterCode => 'Were you invited? Enter their code';

  @override
  String get referralCount => 'Referrals';

  @override
  String get referralEarnings => 'Coins earned';

  @override
  String get referralDialogTitle => 'Were you invited?';

  @override
  String get referralDialogSubtitle => 'Enter your friend\'s code.';

  @override
  String get referralBothGet =>
      'You both receive 1,000 coins when you make your first cashout.';

  @override
  String get referralApplyCode => 'Apply code';

  @override
  String get referralHowTitle => 'How the bonus works';

  @override
  String get referralHowStep1 =>
      'Enter the code of the person who invited you.';

  @override
  String get referralHowStep2 =>
      'You and your friend each receive 1,000 coins.';

  @override
  String get referralHowStep3 =>
      'The bonus is credited when you complete your first successful cashout.';

  @override
  String get referralHowStep4 =>
      'You can only register a code once and before your first cashout.';

  @override
  String get referralHowGotIt => 'Got it';

  @override
  String get referralRegistered =>
      '🎁 Code registered! The bonus (1,000 coins each) will be credited when you make your first cashout.';

  @override
  String get rankingTitle => 'Weekly Ranking';

  @override
  String get rankingSubtitle => 'Top players of the week';

  @override
  String get rankingResetsMonday => 'Resets every Monday';

  @override
  String get rankingBeFirst => 'Be the first!';

  @override
  String get rankingEmptyDesc =>
      'Nobody has earned coins this week.\nThe ranking fills up as players compete.';

  @override
  String get rankingMyPosition => 'Your current position';

  @override
  String get rankingEarnToClimb => 'Earn coins to climb';

  @override
  String get rankingTipGames => 'Install games and complete missions';

  @override
  String get rankingSurveysTip => 'Complete surveys and earn fast';

  @override
  String get rankingVideosTip => 'Watch 20 daily videos to accumulate';

  @override
  String rankingPositions(int total) {
    return 'POSITIONS 4 – $total';
  }

  @override
  String get rankingMyPositionBar => 'Your position this week';

  @override
  String get rankingKeepPlaying => 'Keep playing to climb!';

  @override
  String get rankingLoadError => 'Could not load ranking';

  @override
  String get rankingRetry => 'Retry';

  @override
  String get rankingYou => 'YOU';

  @override
  String get surveysTitle => 'Available surveys';

  @override
  String surveysUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String surveysCount(int count, String time) {
    return '$count survey • $time';
  }

  @override
  String surveysCountPlural(int count, String time) {
    return '$count surveys • $time';
  }

  @override
  String get surveysRefresh => 'Refresh';

  @override
  String get surveysEarn => 'You earn ';

  @override
  String get surveysPerSurvey => ' per completed survey';

  @override
  String get surveysEmpty => 'No surveys available';

  @override
  String get surveysEmptySubtitle => 'Come back later or tap refresh';

  @override
  String surveysTimeAgoSeconds(int sec) {
    return '${sec}s ago';
  }

  @override
  String surveysTimeAgoMinutes(int min) {
    return '$min min ago';
  }

  @override
  String surveysTimeAgoHours(int hr) {
    return '${hr}h ago';
  }

  @override
  String surveysCoinsEarned(String coins) {
    return '+$coins coins — survey completed';
  }

  @override
  String get videosTitle => 'Available videos';

  @override
  String get videosTodayTitle => 'Today\'s videos';

  @override
  String videosEarnedToday(int coins) {
    return '$coins coins earned today';
  }

  @override
  String get videosLimitReached => 'Limit reached';

  @override
  String get videosResetsIn => 'Videos available in';

  @override
  String get videosRetry => 'Retry';

  @override
  String get videosUnavailable => 'Not available\nright now';

  @override
  String get videosWatch => 'Watch';

  @override
  String get videosHowItWorks => 'How it works';

  @override
  String get videosInfoFull => 'Watch the full ad to earn coins';

  @override
  String get videosInfoLimit => 'Limit of 50 ads per day';

  @override
  String get videosInfoCoins => '30 coins per completed ad';

  @override
  String get videosInfoAccumulate =>
      'Accumulate 10,000 coins to cash out \$1.00';

  @override
  String get videosAvailabilityNote =>
      'Ads load based on availability. If they don\'t appear, tap \"Retry\" in a few seconds.';

  @override
  String videosCoinsEarned(int coins) {
    return '+$coins coins earned';
  }

  @override
  String videosErrorCredit(String error) {
    return 'Error crediting coins: $error';
  }

  @override
  String videosSlot(int number) {
    return 'Video $number';
  }

  @override
  String get walletErrorLoading => 'Error loading';

  @override
  String walletCoinsAvailable(String coins) {
    return '$coins coins available';
  }

  @override
  String get walletRequestCashout => 'Request cashout';

  @override
  String get walletMinimumCashout => 'Minimum \$1.00 to withdraw';

  @override
  String get walletPaymentMethods => 'Payment methods';

  @override
  String get walletPaypalDesc => 'International · 1–3 business days';

  @override
  String get walletMercadopagoDesc => 'Mexico and LatAm · no fee';

  @override
  String get walletComingSoon => 'Coming soon';

  @override
  String get walletComingSoonFull => 'Coming soon';

  @override
  String get walletTransactions => 'Recent transactions';

  @override
  String get walletNoTransactions => 'No transactions yet';

  @override
  String get walletAlmostThere => 'Almost there!';

  @override
  String walletNeedCoins(String coins, String missing) {
    return 'You need at least $coins coins (\$1.00 USD) to withdraw.\n\nYou\'re missing $missing coins.';
  }

  @override
  String get walletGotIt => 'Got it';

  @override
  String get cashoutStepRequested => 'Requested';

  @override
  String get cashoutStepRequestedSub => 'We received your request';

  @override
  String get cashoutStepReview => 'In review';

  @override
  String get cashoutStepReviewSub => 'Verifying details';

  @override
  String get cashoutStepProcessing => 'Processing';

  @override
  String get cashoutStepProcessingSub => 'Sending payment';

  @override
  String get cashoutStepPaid => 'Paid';

  @override
  String get cashoutStepPaidSub => 'Money sent!';

  @override
  String get cashoutStatusPending => 'Pending';

  @override
  String get cashoutStatusProcessing => 'Processing';

  @override
  String get cashoutStatusPaid => 'Paid';

  @override
  String get cashoutStatusRejected => 'Rejected';

  @override
  String cashoutRequestHeader(String amount, String method) {
    return 'Cashout of \$$amount USD · $method';
  }

  @override
  String get cashoutPaidBanner => 'Your payment was sent!';

  @override
  String get cashoutPaidBannerSub => 'Check your PayPal account.';

  @override
  String get cashoutReferralBanner => 'Referral code cashed out!';

  @override
  String get cashoutReferralBannerSub =>
      'You and your friend each have 1,000 coins.';

  @override
  String get cashoutTimePending =>
      'Estimated time: 1–3 business days. We\'ll notify you when it\'s sent.';

  @override
  String get cashoutTimeProcessing =>
      'Your payment is being processed. It will arrive at your account soon.';

  @override
  String cashoutPaidOn(String date, String time) {
    return 'Paid on $date at $time';
  }

  @override
  String cashoutRequestedOn(String date, String time) {
    return 'Requested on $date at $time';
  }

  @override
  String get cashoutAppTitle => 'Request cashout';

  @override
  String get cashoutAmountTitle => 'Amount to cash out';

  @override
  String get cashoutMethodTitle => 'Payment method';

  @override
  String get cashoutAccountTitle => 'Your account details';

  @override
  String get cashoutSummaryAmount => 'Amount';

  @override
  String get cashoutSummaryCoins => 'Coins to deduct';

  @override
  String get cashoutSummaryMethod => 'Method';

  @override
  String cashoutConfirm(String amount) {
    return 'Confirm cashout of \$$amount';
  }

  @override
  String get cashoutProcessingNote =>
      'We process your payment in 1–3 business days';

  @override
  String get cashoutEnterAccount => 'Enter your account details';

  @override
  String get cashoutSentSuccess =>
      'Request sent! We\'ll process it in 1–3 business days';

  @override
  String cashoutUsdAvailable(String usd) {
    return '\$$usd USD available';
  }

  @override
  String cashoutCoins(String coins) {
    return '$coins coins';
  }

  @override
  String cashoutNeedCoins(String coins, String missing) {
    return 'You need at least $coins coins (\$1.00 USD) to withdraw via PayPal.\n\nYou\'re missing $missing coins.';
  }

  @override
  String get cashoutGuestTitle => 'Create an account to cash out';

  @override
  String get cashoutGuestSubtitle =>
      'You\'re playing as a guest. Link your account\nand keep all the coins you earned.';

  @override
  String get cashoutGuestCurrentCoins => 'Your current coins';

  @override
  String cashoutGuestCoins(String coins) {
    return '$coins coins';
  }

  @override
  String get cashoutGuestContinueGoogle => 'Continue with Google';

  @override
  String get cashoutGuestContinueApple => 'Continue with Apple';

  @override
  String get cashoutGuestCreateEmail => 'Create account with email';

  @override
  String get cashoutGuestNote =>
      'Your coins will be automatically transferred\nto your new account.';

  @override
  String get cashoutGuestLinked => 'Account linked! Your coins were preserved.';

  @override
  String get cashoutGuestCreated => 'Account created! Your coins were saved.';

  @override
  String get profileFirstName => 'First name';

  @override
  String get profileLastName => 'Last name';

  @override
  String cashoutMinLabel(String usd) {
    return '$usd min';
  }

  @override
  String cashoutMaxLabel(String usd) {
    return '$usd max';
  }

  @override
  String cashoutGuestLinkedErrorGoogle(String error) {
    return 'Error linking with Google: $error';
  }

  @override
  String cashoutGuestLinkedErrorApple(String error) {
    return 'Error linking with Apple: $error';
  }

  @override
  String get cashoutCreateEmailTitle => 'Create account with email';

  @override
  String get cashoutCreateEmailSubtitle =>
      'Your coins will be preserved automatically.';

  @override
  String get cashoutCreateEmailButton => 'Create account and keep coins';

  @override
  String get cashoutPasswordMismatch => 'Passwords do not match';

  @override
  String get cashoutPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get cashoutPaypalSubtitle =>
      'International · processed in 1–3 business days';

  @override
  String get cashoutMercadopagoSubtitle => 'Coming soon';

  @override
  String get gamesTitle => 'Offers & Games';

  @override
  String get gamesAvailable => '🎮 Now available!';

  @override
  String get gamesSoon => '🚀 Coming soon';

  @override
  String get gamesDescription =>
      'Install games and apps to earn\nextra coins without watching ads.';

  @override
  String get gamesOpenButton => '🎮  See Games and Earn';

  @override
  String get gamesExploreSoon => '🔓  View Catalog';

  @override
  String get gamesInstallGames => 'Install games';

  @override
  String get gamesInstallGamesDesc =>
      'Earn coins by installing and playing new games.';

  @override
  String get gamesDownloadApps => 'Download apps';

  @override
  String get gamesDownloadAppsDesc =>
      'Complete tasks in apps and receive coins instantly.';

  @override
  String get gamesCompleteMissions => 'Complete missions';

  @override
  String get gamesCompleteMissionsDesc =>
      'Reach a specific level in a game and earn much more.';

  @override
  String get gamesOpenCatalog =>
      'Tap the button above to see the full catalog of games and offers.';

  @override
  String get gamesComingNotify =>
      'We\'ll notify you when this section is available.';

  @override
  String get gamesOpenError => 'Could not open catalog. Please try again.';

  @override
  String get gamesComingSoonTitle => 'Coming soon';

  @override
  String get gamesComingSoonContent =>
      'This section will be available very soon.\nWe\'ll notify you when you can earn coins by installing games!';

  @override
  String get gamesComingSoonButton => 'Got it';

  @override
  String get gamesStatusActive => 'ACTIVE';

  @override
  String get gamesStatusSoon => 'COMING SOON';

  @override
  String get gamesHeroTitle => 'Play and Earn\nReal Coins! 🎮';

  @override
  String get gamesHeroSubtitle =>
      'Download games, complete missions\nand earn redeemable coins.';

  @override
  String get gamesPopularTitle => 'Popular Games';

  @override
  String get gamesSeeAll => 'See all →';

  @override
  String get gamesStatGames => '50+ games';

  @override
  String get gamesStatReward => 'Up to 5,000 🪙';

  @override
  String get gamesStatInstant => 'Instant credit';

  @override
  String get gamesHowTitle => 'How does it work?';

  @override
  String get gamesStep1Title => 'Download a game';

  @override
  String get gamesStep1Desc =>
      'Choose any game from the catalog and download it for free.';

  @override
  String get gamesStep2Title => 'Play and complete missions';

  @override
  String get gamesStep2Desc =>
      'Reach the levels or goals indicated in the offer.';

  @override
  String get gamesStep3Title => 'Earn coins!';

  @override
  String get gamesStep3Desc =>
      'Coins are credited automatically upon completion.';

  @override
  String get gamesFreeLabel => 'FREE';

  @override
  String get gamesMaintenanceTitle => 'Games under maintenance';

  @override
  String get gamesMaintenanceSubtitle =>
      'We\'re preparing something amazing.\nCome back in a few hours.';

  @override
  String get dailyBonusClaimedToast => 'Daily bonus claimed!';

  @override
  String dailyBonusCoinsAndStreak(int coins, int streak, String streakLabel) {
    return '+$coins coins • $streak-$streakLabel streak';
  }

  @override
  String get dailyBonusStreakLabelOne => 'day';

  @override
  String get dailyBonusStreakLabelMany => 'day';

  @override
  String get dailyGoalReachedToast => 'Daily goal reached!';

  @override
  String dailyGoalBonusCoins(String coins) {
    return '+$coins bonus coins';
  }

  @override
  String get profileEditNameTitle => 'Edit name';

  @override
  String get profileEditNameHint => 'Your name';

  @override
  String get profileSave => 'Save';

  @override
  String get profileNameUpdated => '✅ Name updated';

  @override
  String get profileLanguageTitle => 'Language';

  @override
  String get profileLanguageSubtitle => 'Español / English / Português';

  @override
  String get profileLanguageDialogTitle => 'Select language';

  @override
  String get profileLanguageEs => '🇲🇽  Español';

  @override
  String get profileLanguageEn => '🇺🇸  English';

  @override
  String get profileLanguagePt => '🇧🇷  Português';

  @override
  String get profileLanguageAuto => 'Automatic (device)';

  @override
  String get versionUpdateTitle => 'Update required!';

  @override
  String get versionUpdateBody =>
      'To keep earning money with JUEGALO you need to install the latest version. It brings improvements and more ways to earn!';

  @override
  String get versionUpdateButton => 'Update now';

  @override
  String get versionUpdateNote =>
      'The update is free and only takes a few seconds.';

  @override
  String get versionNewAvailable => '🚀 New version available';

  @override
  String get rankingPos1 => 'Place #1';

  @override
  String get rankingPos2 => 'Place #2';

  @override
  String get rankingPos3 => 'Place #3';

  @override
  String get rankingTop50 => 'TOP 50';

  @override
  String get rankingTop3Label => 'TOP 3';

  @override
  String get rankingThisWeek => 'this week';

  @override
  String rankingStreakDays(int days) {
    return '$days consecutive days';
  }

  @override
  String get rankingCelebFirst => 'First place!';

  @override
  String get rankingCelebSecond => 'Second place!';

  @override
  String get rankingCelebThird => 'Third place!';

  @override
  String get rankingCelebSubtitle =>
      'Last week you were one\nof the top players.';

  @override
  String get rankingCelebCoinsLabel => 'coins credited';

  @override
  String get rankingCelebButton => 'Awesome! 🎉';

  @override
  String get rankingInfoTitle => 'How does the ranking work?';

  @override
  String get rankingInfoSubtitle =>
      'Be among the best players of the week\nand earn coin rewards.';

  @override
  String get rankingInfoFirst => 'First place';

  @override
  String get rankingInfoFirstDesc =>
      'The player with the most coins accumulated in the week wins';

  @override
  String get rankingInfoSecond => 'Second place';

  @override
  String get rankingInfoSecondDesc => 'Second place at weekly close wins';

  @override
  String get rankingInfoThird => 'Third place';

  @override
  String get rankingInfoThirdDesc => 'Third place at weekly close wins';

  @override
  String get rankingInfoHowToEarn => '💡 How to earn coins?';

  @override
  String get rankingInfoTipGames => 'Install games and complete missions';

  @override
  String get rankingInfoTipSurveys => 'Complete daily surveys';

  @override
  String get rankingInfoTipVideos => 'Watch up to 20 videos a day';

  @override
  String get rankingInfoTipStreak => 'Keep your daily streak for extra bonuses';

  @override
  String get rankingInfoGotIt => 'Got it!';

  @override
  String get rankingLastWinnersTitle => '🏆  LAST WEEK\'S WINNERS';

  @override
  String get rankingLastWinnersPrize => 'prize';

  @override
  String get txHistoryTitle => 'Full history';

  @override
  String get txFilterAll => 'All';

  @override
  String get txFilterVideos => 'Videos';

  @override
  String get txFilterSurveys => 'Surveys';

  @override
  String get txFilterBonus => 'Bonuses';

  @override
  String get txFilterCashout => 'Cashouts';

  @override
  String get txGroupToday => 'Today';

  @override
  String get txGroupYesterday => 'Yesterday';

  @override
  String get txGroupThisWeek => 'This week';

  @override
  String get txGroupThisMonth => 'This month';

  @override
  String get txGroupOlder => 'Older';

  @override
  String get txLoadMore => 'Load more';

  @override
  String get txEmpty => 'No transactions yet';

  @override
  String get txEmptyFilter => 'No transactions of this type';

  @override
  String get txSeeAll => 'See all';

  @override
  String get phoneVerifyInvalidNumber => 'Enter a valid phone number';

  @override
  String get phoneVerifyUnexpectedError => 'Unexpected error. Try again.';

  @override
  String get phoneVerifyCodeLength => 'The code has 6 digits';

  @override
  String get phoneVerifyErrorInvalidExpired =>
      'Incorrect or expired code. Request a new one.';

  @override
  String get phoneVerifyErrorRateLimit =>
      'Too many attempts. Wait a few minutes.';

  @override
  String get phoneVerifyErrorAlreadyRegistered =>
      'This number is already registered to another account. Use a different number.';

  @override
  String get phoneVerifyErrorInvalidPhone =>
      'Invalid phone number. Check the format and try again.';

  @override
  String get phoneVerifyErrorNetwork =>
      'Connection error. Check your internet and try again.';

  @override
  String get phoneVerifyErrorGeneric =>
      'An unexpected error occurred. Try again.';

  @override
  String get phoneVerifyTitleOtpSent => 'Code sent';

  @override
  String get phoneVerifyTitleEnterPhone => 'Verify your number';

  @override
  String phoneVerifySubtitleOtpSent(String phone) {
    return 'Enter the 6-digit code\nwe sent to $phone';
  }

  @override
  String get phoneVerifySubtitlePhone =>
      'A quick step to protect\nyour money. Only done once.';

  @override
  String get phoneVerifyStep1of2 => 'Step 1 of 2';

  @override
  String get phoneVerifyStep2of2 => 'Step 2 of 2';

  @override
  String get phoneVerifyLabelPhone => 'Phone number';

  @override
  String get phoneVerifyLabelCode => 'Verification code';

  @override
  String get phoneVerifyButtonVerify => 'Verify code';

  @override
  String get phoneVerifyButtonSend => 'Send SMS';

  @override
  String phoneVerifyResendIn(int secs) {
    return 'Resend in ${secs}s';
  }

  @override
  String get phoneVerifyResend => 'Resend code';

  @override
  String get phoneVerifyChangeNumber => 'Change number';

  @override
  String get phoneVerifyPrivacyNote =>
      'Your number is only used to verify your identity. You won\'t receive spam.';

  @override
  String get phoneVerifyCountryPickerTitle => 'Select your country';

  @override
  String get phoneVerifyCountrySearch => 'Search country or code...';

  @override
  String get phoneVerifyNoResults => 'No results';

  @override
  String get cashoutPhoneRequired =>
      'You must verify your phone to withdraw coins';

  @override
  String get cashoutGateTitle => 'Verify your phone\nto cash out';

  @override
  String get cashoutGateStep1Title => 'Enter your number';

  @override
  String get cashoutGateStep1Subtitle => 'With country code (+52, +1…)';

  @override
  String get cashoutGateStep2Title => 'Receive the SMS';

  @override
  String get cashoutGateStep2Subtitle => '6-digit code in seconds';

  @override
  String get cashoutGateStep3Title => 'Ready to cash out!';

  @override
  String get cashoutGateStep3Subtitle => 'Never asked again';

  @override
  String get cashoutGateButton => 'Verify my phone';

  @override
  String get cashoutCurrencyTitle => 'Select currency';

  @override
  String cashoutCurrencyCount(int count) {
    return '$count currencies';
  }

  @override
  String get cashoutCurrencySearch => 'Search currency or code (USD, EUR…)';

  @override
  String get profileUnverifiedAccount => 'Unverified account';
}
