// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get tutorialWelcomeTitle => 'Bem-vindo ao JUEGALO!';

  @override
  String get tutorialWelcomeSubtitle =>
      'O app onde você joga, faz\npesquisas e ganha dinheiro real.';

  @override
  String get tutorialWelcomeFree => '100% grátis para sempre';

  @override
  String get tutorialWelcomeFreeValue => 'Sem cobranças';

  @override
  String get tutorialWelcomeLatam => 'Disponível na América Latina';

  @override
  String get tutorialWelcomeLatamValue => 'A partir de hoje';

  @override
  String get tutorialWelcomeStart => 'Comece a ganhar em 1 minuto';

  @override
  String get tutorialWelcomeStartValue => 'Rápido';

  @override
  String get tutorialEarnTitle => 'Ganhe moedas fácil';

  @override
  String get tutorialEarnSubtitle =>
      'Três formas de acumular\nmoedas todo dia.';

  @override
  String get tutorialEarnVideos => 'Vídeos curtos';

  @override
  String get tutorialEarnVideosValue => '+50 moedas c/u';

  @override
  String get tutorialEarnSurveys => 'Pesquisas';

  @override
  String get tutorialEarnSurveysValue => 'até 500 moedas';

  @override
  String get tutorialEarnGames => 'Jogos';

  @override
  String get tutorialEarnGamesValue => 'até 2.000 moedas';

  @override
  String get tutorialRankingTitle => 'Ranking semanal';

  @override
  String get tutorialRankingSubtitle =>
      'Compita toda semana.\nOs melhores ganham prêmios extras.';

  @override
  String get tutorialRankingFirst => '1º Lugar';

  @override
  String get tutorialRankingFirstValue => '2.500 moedas';

  @override
  String get tutorialRankingSecond => '2º Lugar';

  @override
  String get tutorialRankingSecondValue => '1.000 moedas';

  @override
  String get tutorialRankingThird => '3º Lugar';

  @override
  String get tutorialRankingThirdValue => '500 moedas';

  @override
  String get tutorialCashoutTitle => 'Saque quando quiser';

  @override
  String get tutorialCashoutSubtitle =>
      '10.000 moedas = \$1,00 USD.\nSaque a partir de \$1 sem taxa.';

  @override
  String get tutorialCashoutPaypalValue => 'Instantâneo';

  @override
  String get tutorialSkip => 'Pular';

  @override
  String get tutorialNext => 'Próximo';

  @override
  String get tutorialStartEarning => 'Começar a ganhar!';

  @override
  String get onboardingTagline => 'Jogue. Ganhe. Saque.';

  @override
  String get onboardingPaidBadge => '+\$12.847 pagos';

  @override
  String get onboardingHowItWorks => 'Como funciona?';

  @override
  String get onboardingFeaturePlay => 'Jogue';

  @override
  String get onboardingFeaturePlaySubtitle =>
      'Instale jogos grátis e acumule moedas';

  @override
  String get onboardingFeatureSurveys => 'Pesquisas';

  @override
  String get onboardingFeatureSurveysSubtitle =>
      'Ganhe moedas por cada pesquisa concluída';

  @override
  String get onboardingFeatureCashout => 'Saque';

  @override
  String get onboardingFeatureCashoutSubtitle =>
      'Retire para o PayPal a partir de \$1 USD';

  @override
  String get onboardingStartNow => 'Comece agora';

  @override
  String get onboardingContinueGoogle => 'Continuar com Google';

  @override
  String get onboardingContinueApple => 'Continuar com Apple';

  @override
  String get onboardingContinueEmail => 'Continuar com e-mail';

  @override
  String get onboardingPlayGuest => 'Jogar sem conta';

  @override
  String get onboardingLegal =>
      'Ao continuar você aceita os Termos de uso\ne a Política de privacidade';

  @override
  String get onboardingOr => 'ou';

  @override
  String get onboardingErrorWrongCredentials => 'E-mail ou senha incorretos';

  @override
  String onboardingErrorGeneric(String msg) {
    return 'Erro ao entrar: $msg';
  }

  @override
  String get emailDialogTitle => 'Entrar';

  @override
  String get emailDialogSubtitle => 'E-mail e senha';

  @override
  String get emailDialogEmail => 'E-mail';

  @override
  String get emailDialogPassword => 'Senha';

  @override
  String get emailDialogSignIn => 'Entrar';

  @override
  String get homeTabGames => 'Jogos';

  @override
  String get homeTabSurveys => 'Pesquisas';

  @override
  String get homeTabVideos => 'Vídeos';

  @override
  String get homeTabRanking => 'Ranking';

  @override
  String get homeTabWallet => 'Sacar';

  @override
  String get balanceCardLabel => 'Seu saldo';

  @override
  String balanceCardCoins(String coins) {
    return '$coins moedas';
  }

  @override
  String get balanceCardCashout => 'Sacar';

  @override
  String get dailyBonusTitle => 'Bônus diário';

  @override
  String get dailyBonusStreakZero => 'Comece sua sequência hoje';

  @override
  String dailyBonusStreakOne(int count) {
    return '$count dia seguido';
  }

  @override
  String dailyBonusStreakMany(int count) {
    return '$count dias seguidos';
  }

  @override
  String dailyBonusDays(int count) {
    return '$count dias';
  }

  @override
  String get dailyBonusClaimed => 'Resgatado hoje';

  @override
  String get dailyBonusTodayPrize => 'Prêmio de hoje';

  @override
  String dailyBonusCoins(String coins) {
    return '+$coins moedas';
  }

  @override
  String dailyBonusNextMilestone(int day, String coins) {
    return 'Dia $day → +$coins moedas';
  }

  @override
  String get dailyBonusClaimedBadge => 'Resgatado';

  @override
  String get dailyBonusDayMon => 'Seg';

  @override
  String get dailyBonusDayTue => 'Ter';

  @override
  String get dailyBonusDayWed => 'Qua';

  @override
  String get dailyBonusDayThu => 'Qui';

  @override
  String get dailyBonusDayFri => 'Sex';

  @override
  String get dailyBonusDaySat => 'Sáb';

  @override
  String get dailyBonusDaySun => 'Dom';

  @override
  String get dailyGoalReached => 'Meta! +1.500 🎯';

  @override
  String get dailyGoalLabel => 'Meta de hoje';

  @override
  String dailyGoalRemaining(String coins) {
    return 'Faltam $coins moedas para o bônus de 1.500 moedas grátis.';
  }

  @override
  String get profileTitle => 'Meu perfil';

  @override
  String get profileCurrentCoins => 'Moedas atuais';

  @override
  String get profileTotalEarned => 'Total ganho (USD)';

  @override
  String get profileCurrentStreak => 'Sequência atual';

  @override
  String profileStreakDays(int days) {
    return '$days dias';
  }

  @override
  String get profileSignOut => 'Sair';

  @override
  String get profileDeleteAccount => 'Excluir minha conta';

  @override
  String get profileIdCopied => 'ID copiado para a área de transferência';

  @override
  String get profilePhotoUpdated => 'Foto atualizada!';

  @override
  String profilePhotoError(String error) {
    return 'Erro ao enviar foto: $error';
  }

  @override
  String get profileTakePhoto => 'Tirar foto';

  @override
  String get profileChooseGallery => 'Escolher da galeria';

  @override
  String get profileDeleteTitle => 'Excluir conta';

  @override
  String get profileDeleteContent =>
      'Esta ação é irreversível.\n\nSeu perfil, histórico e saldo de moedas serão excluídos. As solicitações de saque pendentes são mantidas por 90 dias por obrigação legal.\n\nTem certeza que deseja continuar?';

  @override
  String get profileDeleteConfirm => 'Sim, excluir';

  @override
  String get profileCancel => 'Cancelar';

  @override
  String get profileConnectionError => 'Erro de conexão. Tente novamente.';

  @override
  String get profileVerifiedAccount => 'Conta verificada';

  @override
  String get profileNoEmail => 'Sem e-mail cadastrado';

  @override
  String get profileGuestTitle => 'Você está como convidado';

  @override
  String get profileGuestSubtitle =>
      'Vincule sua conta para não perder suas moedas';

  @override
  String get profileLinkGoogle => 'Vincular com Google';

  @override
  String get profileLinkApple => 'Vincular com Apple';

  @override
  String get profileLinkEmail => 'Vincular com e-mail';

  @override
  String get profileCoinsPreserved =>
      'Suas moedas são mantidas ao vincular sua conta.';

  @override
  String get profileLinkEmailTitle => 'Vincular com e-mail';

  @override
  String get profileLinkEmailSubtitle => 'Suas moedas serão mantidas.';

  @override
  String get profileConfirmPassword => 'Confirmar senha';

  @override
  String get profileLinkSave => 'Vincular e salvar moedas';

  @override
  String get profilePasswordMismatch => 'As senhas não coincidem';

  @override
  String get profilePasswordTooShort => 'Mínimo 6 caracteres';

  @override
  String get profileLinkedGoogle => 'Conta vinculada com Google!';

  @override
  String get profileLinkedApple => 'Conta vinculada com Apple!';

  @override
  String get profileLinkedEmail => 'Conta criada! Suas moedas foram mantidas.';

  @override
  String get referralInviteFriends => 'Convide amigos';

  @override
  String get referralBothEarn => 'Vocês dois ganham 1.000 moedas';

  @override
  String get referralYourCode => 'Seu código';

  @override
  String get referralCopy => 'Copiar';

  @override
  String get referralShare => 'Compartilhar código';

  @override
  String referralShareMessage(String code) {
    return 'Entre no JUEGALO e ganhe dinheiro real jogando, fazendo pesquisas e assistindo vídeos! 🎮💰\n\nUse meu código ao se cadastrar e os dois ganhamos 1.000 moedas quando você fizer seu primeiro saque.\n\n📱 Código: $code\n\nBaixe o app: juegalo.app';
  }

  @override
  String get referralShareSubject => 'Ganhe dinheiro com JUEGALO';

  @override
  String get referralCodeCopied =>
      'Código copiado para a área de transferência';

  @override
  String get referralBonusPaid => 'Bônus de indicação recebido';

  @override
  String get referralBonusPending => 'Bônus pendente';

  @override
  String get referralBonusPaidDesc =>
      '+1.000 moedas já foram adicionadas à sua conta.';

  @override
  String get referralBonusPendingDesc =>
      'Você receberá 1.000 moedas ao fazer seu primeiro saque.';

  @override
  String get referralRegisterCode =>
      'Foi convidado por alguém? Registre o código';

  @override
  String get referralCount => 'Indicados';

  @override
  String get referralEarnings => 'Moedas ganhas';

  @override
  String get referralDialogTitle => 'Foi convidado por alguém?';

  @override
  String get referralDialogSubtitle => 'Insira o código do seu amigo.';

  @override
  String get referralBothGet =>
      'Os dois recebem 1.000 moedas quando você fizer seu primeiro saque.';

  @override
  String get referralApplyCode => 'Aplicar código';

  @override
  String get referralHowTitle => 'Como funciona o bônus';

  @override
  String get referralHowStep1 => 'Insira o código de quem te convidou.';

  @override
  String get referralHowStep2 =>
      'Você e seu amigo recebem 1.000 moedas cada um.';

  @override
  String get referralHowStep3 =>
      'O bônus é creditado quando você concluir seu primeiro saque.';

  @override
  String get referralHowStep4 =>
      'Você só pode registrar um código uma vez e antes do seu primeiro saque.';

  @override
  String get referralHowGotIt => 'Entendi';

  @override
  String get referralRegistered =>
      '🎁 Código registrado! O bônus (1.000 moedas cada) é creditado quando você fizer seu primeiro saque.';

  @override
  String get rankingTitle => 'Ranking Semanal';

  @override
  String get rankingSubtitle => 'Top jogadores da semana';

  @override
  String get rankingResetsMonday => 'Reinicia toda segunda-feira';

  @override
  String get rankingBeFirst => 'Seja o primeiro!';

  @override
  String get rankingEmptyDesc =>
      'Ninguém ganhou moedas esta semana.\nO ranking se preenche conforme os jogadores competem.';

  @override
  String get rankingMyPosition => 'Sua posição atual';

  @override
  String get rankingEarnToClimb => 'Ganhe moedas para subir';

  @override
  String get rankingTipGames => 'Instale jogos e complete missões';

  @override
  String get rankingSurveysTip => 'Complete pesquisas e ganhe rápido';

  @override
  String get rankingVideosTip => 'Assista 20 vídeos diários para acumular';

  @override
  String rankingPositions(int total) {
    return 'POSIÇÕES 4 – $total';
  }

  @override
  String get rankingMyPositionBar => 'Sua posição esta semana';

  @override
  String get rankingKeepPlaying => 'Continue jogando para subir!';

  @override
  String get rankingLoadError => 'Não foi possível carregar o ranking';

  @override
  String get rankingRetry => 'Tentar novamente';

  @override
  String get rankingYou => 'VOCÊ';

  @override
  String get surveysTitle => 'Pesquisas disponíveis';

  @override
  String surveysUpdated(String time) {
    return 'Atualizado $time';
  }

  @override
  String surveysCount(int count, String time) {
    return '$count pesquisa • $time';
  }

  @override
  String surveysCountPlural(int count, String time) {
    return '$count pesquisas • $time';
  }

  @override
  String get surveysRefresh => 'Atualizar';

  @override
  String get surveysEarn => 'Você ganha ';

  @override
  String get surveysPerSurvey => ' por cada pesquisa concluída';

  @override
  String get surveysEmpty => 'Nenhuma pesquisa disponível';

  @override
  String get surveysEmptySubtitle => 'Volte mais tarde ou toque em atualizar';

  @override
  String surveysTimeAgoSeconds(int sec) {
    return 'há ${sec}s';
  }

  @override
  String surveysTimeAgoMinutes(int min) {
    return 'há $min min';
  }

  @override
  String surveysTimeAgoHours(int hr) {
    return 'há ${hr}h';
  }

  @override
  String surveysCoinsEarned(String coins) {
    return '+$coins moedas — pesquisa concluída';
  }

  @override
  String get videosTitle => 'Vídeos disponíveis';

  @override
  String get videosTodayTitle => 'Vídeos de hoje';

  @override
  String videosEarnedToday(int coins) {
    return '$coins moedas ganhas hoje';
  }

  @override
  String get videosLimitReached => 'Limite atingido';

  @override
  String get videosResetsIn => 'Vídeos disponíveis em';

  @override
  String get videosRetry => 'Tentar novamente';

  @override
  String get videosUnavailable => 'Não disponível\nagora';

  @override
  String get videosWatch => 'Assistir';

  @override
  String get videosHowItWorks => 'Como funciona';

  @override
  String get videosInfoFull => 'Assista o anúncio completo para ganhar moedas';

  @override
  String get videosInfoLimit => 'Limite de 50 anúncios por dia';

  @override
  String get videosInfoCoins => '30 moedas por anúncio concluído';

  @override
  String get videosInfoAccumulate => 'Acumule 10.000 moedas para sacar \$1,00';

  @override
  String get videosAvailabilityNote =>
      'Os anúncios são carregados conforme disponibilidade. Se não aparecerem, toque em \"Tentar novamente\" em alguns segundos.';

  @override
  String videosCoinsEarned(int coins) {
    return '+$coins moedas ganhas';
  }

  @override
  String videosErrorCredit(String error) {
    return 'Erro ao creditar moedas: $error';
  }

  @override
  String videosSlot(int number) {
    return 'Vídeo $number';
  }

  @override
  String get walletErrorLoading => 'Erro ao carregar';

  @override
  String walletCoinsAvailable(String coins) {
    return '$coins moedas disponíveis';
  }

  @override
  String get walletRequestCashout => 'Solicitar saque';

  @override
  String get walletMinimumCashout => 'Mínimo \$1,00 para sacar';

  @override
  String get walletPaymentMethods => 'Métodos de saque';

  @override
  String get walletPaypalDesc => 'Internacional · 1–3 dias úteis';

  @override
  String get walletMercadopagoDesc => 'México e LatAm · sem taxa';

  @override
  String get walletComingSoon => 'Em breve';

  @override
  String get walletComingSoonFull => 'Em breve disponível';

  @override
  String get walletTransactions => 'Últimas transações';

  @override
  String get walletNoTransactions => 'Sem transações ainda';

  @override
  String get walletAlmostThere => 'Quase lá!';

  @override
  String walletNeedCoins(String coins, String missing) {
    return 'Você precisa de pelo menos $coins moedas (\$1,00 USD) para sacar.\n\nFaltam $missing moedas.';
  }

  @override
  String get walletGotIt => 'Entendi';

  @override
  String get cashoutStepRequested => 'Solicitado';

  @override
  String get cashoutStepRequestedSub => 'Recebemos sua solicitação';

  @override
  String get cashoutStepReview => 'Em revisão';

  @override
  String get cashoutStepReviewSub => 'Verificando os dados';

  @override
  String get cashoutStepProcessing => 'Processando';

  @override
  String get cashoutStepProcessingSub => 'Enviando o pagamento';

  @override
  String get cashoutStepPaid => 'Pago';

  @override
  String get cashoutStepPaidSub => 'Dinheiro enviado!';

  @override
  String get cashoutStatusPending => 'Pendente';

  @override
  String get cashoutStatusProcessing => 'Em processo';

  @override
  String get cashoutStatusPaid => 'Pago';

  @override
  String get cashoutStatusRejected => 'Rejeitado';

  @override
  String cashoutRequestHeader(String amount, String method) {
    return 'Saque de \$$amount USD · $method';
  }

  @override
  String get cashoutPaidBanner => 'Seu pagamento foi enviado!';

  @override
  String get cashoutPaidBannerSub => 'Verifique sua conta do PayPal.';

  @override
  String get cashoutReferralBanner => 'Código de indicação resgatado!';

  @override
  String get cashoutReferralBannerSub =>
      'Você e seu amigo já têm suas 1.000 moedas.';

  @override
  String get cashoutTimePending =>
      'Tempo estimado: 1–3 dias úteis. Avisaremos quando for enviado.';

  @override
  String get cashoutTimeProcessing =>
      'Seu pagamento está sendo processado. Chegará em breve à sua conta.';

  @override
  String cashoutPaidOn(String date, String time) {
    return 'Pago em $date às $time';
  }

  @override
  String cashoutRequestedOn(String date, String time) {
    return 'Solicitado em $date às $time';
  }

  @override
  String get cashoutAppTitle => 'Solicitar saque';

  @override
  String get cashoutAmountTitle => 'Valor a sacar';

  @override
  String get cashoutMethodTitle => 'Método de saque';

  @override
  String get cashoutAccountTitle => 'Dados da sua conta';

  @override
  String get cashoutSummaryAmount => 'Valor';

  @override
  String get cashoutSummaryCoins => 'Moedas a descontar';

  @override
  String get cashoutSummaryMethod => 'Método';

  @override
  String cashoutConfirm(String amount) {
    return 'Confirmar saque de \$$amount';
  }

  @override
  String get cashoutProcessingNote =>
      'Processamos seu pagamento em 1–3 dias úteis';

  @override
  String get cashoutEnterAccount => 'Insira os dados da sua conta';

  @override
  String get cashoutSentSuccess =>
      'Solicitação enviada! Processamos em 1-3 dias úteis';

  @override
  String cashoutUsdAvailable(String usd) {
    return '\$$usd USD disponíveis';
  }

  @override
  String cashoutCoins(String coins) {
    return '$coins moedas';
  }

  @override
  String cashoutNeedCoins(String coins, String missing) {
    return 'Você precisa de pelo menos $coins moedas (\$1,00 USD) para sacar pelo PayPal.\n\nFaltam $missing moedas.';
  }

  @override
  String get cashoutGuestTitle => 'Crie uma conta para sacar';

  @override
  String get cashoutGuestSubtitle =>
      'Você está jogando como convidado. Vincule sua conta\ne mantenha todas as moedas que ganhou.';

  @override
  String get cashoutGuestCurrentCoins => 'Suas moedas atuais';

  @override
  String cashoutGuestCoins(String coins) {
    return '$coins moedas';
  }

  @override
  String get cashoutGuestContinueGoogle => 'Continuar com Google';

  @override
  String get cashoutGuestContinueApple => 'Continuar com Apple';

  @override
  String get cashoutGuestCreateEmail => 'Criar conta com e-mail';

  @override
  String get cashoutGuestNote =>
      'Suas moedas serão transferidas automaticamente\npara sua nova conta.';

  @override
  String get cashoutGuestLinked =>
      'Conta vinculada! Suas moedas foram mantidas.';

  @override
  String get cashoutGuestCreated => 'Conta criada! Suas moedas foram mantidas.';

  @override
  String get profileFirstName => 'Nome';

  @override
  String get profileLastName => 'Sobrenome';

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
    return 'Erro ao vincular com Google: $error';
  }

  @override
  String cashoutGuestLinkedErrorApple(String error) {
    return 'Erro ao vincular com Apple: $error';
  }

  @override
  String get cashoutCreateEmailTitle => 'Criar conta com e-mail';

  @override
  String get cashoutCreateEmailSubtitle =>
      'Suas moedas serão mantidas automaticamente.';

  @override
  String get cashoutCreateEmailButton => 'Criar conta e manter moedas';

  @override
  String get cashoutPasswordMismatch => 'As senhas não coincidem';

  @override
  String get cashoutPasswordTooShort =>
      'A senha deve ter pelo menos 6 caracteres';

  @override
  String get cashoutPaypalSubtitle =>
      'Internacional · processamos em 1–3 dias úteis';

  @override
  String get cashoutMercadopagoSubtitle => 'Em breve disponível';

  @override
  String get gamesTitle => 'Ofertas e Jogos';

  @override
  String get gamesAvailable => '🎮 Já disponível!';

  @override
  String get gamesSoon => '🚀 Em breve';

  @override
  String get gamesDescription =>
      'Instale jogos e apps para ganhar\nmoedas extras sem assistir anúncios.';

  @override
  String get gamesOpenButton => '🎮  Ver Jogos e Ganhar';

  @override
  String get gamesExploreSoon => '🔓  Ver Catálogo';

  @override
  String get gamesInstallGames => 'Instale jogos';

  @override
  String get gamesInstallGamesDesc =>
      'Ganhe moedas por instalar e jogar novos jogos.';

  @override
  String get gamesDownloadApps => 'Baixe apps';

  @override
  String get gamesDownloadAppsDesc =>
      'Complete tarefas em apps e receba moedas na hora.';

  @override
  String get gamesCompleteMissions => 'Complete missões';

  @override
  String get gamesCompleteMissionsDesc =>
      'Chegue a um nível específico em um jogo e ganhe muito mais.';

  @override
  String get gamesOpenCatalog =>
      'Toque no botão acima para ver o catálogo completo de jogos e ofertas.';

  @override
  String get gamesComingNotify =>
      'Avisaremos quando esta seção estiver disponível.';

  @override
  String get gamesOpenError =>
      'Não foi possível abrir o catálogo. Tente novamente.';

  @override
  String get gamesComingSoonTitle => 'Em breve';

  @override
  String get gamesComingSoonContent =>
      'Esta seção estará disponível muito em breve.\nAvisaremos quando você puder ganhar moedas instalando jogos!';

  @override
  String get gamesComingSoonButton => 'Entendi';

  @override
  String get gamesStatusActive => 'ATIVO';

  @override
  String get gamesStatusSoon => 'EM BREVE';

  @override
  String get gamesHeroTitle => 'Jogue e Ganhe\nMoedas Reais! 🎮';

  @override
  String get gamesHeroSubtitle =>
      'Baixe jogos, complete missões\ne acumule moedas resgatáveis.';

  @override
  String get gamesPopularTitle => 'Jogos Populares';

  @override
  String get gamesSeeAll => 'Ver todos →';

  @override
  String get gamesStatGames => '50+ jogos';

  @override
  String get gamesStatReward => 'Até 5.000 🪙';

  @override
  String get gamesStatInstant => 'Crédito imediato';

  @override
  String get gamesHowTitle => 'Como funciona?';

  @override
  String get gamesStep1Title => 'Baixe um jogo';

  @override
  String get gamesStep1Desc =>
      'Escolha qualquer jogo do catálogo e baixe gratuitamente.';

  @override
  String get gamesStep2Title => 'Jogue e complete missões';

  @override
  String get gamesStep2Desc =>
      'Alcance os níveis ou metas indicados na oferta.';

  @override
  String get gamesStep3Title => 'Ganhe moedas!';

  @override
  String get gamesStep3Desc =>
      'As moedas são creditadas automaticamente ao completar.';

  @override
  String get gamesFreeLabel => 'GRÁTIS';

  @override
  String get gamesMaintenanceTitle => 'Jogos em manutenção';

  @override
  String get gamesMaintenanceSubtitle =>
      'Estamos preparando algo incrível.\nVolte em algumas horas.';

  @override
  String get dailyBonusClaimedToast => 'Bônus diário resgatado!';

  @override
  String dailyBonusCoinsAndStreak(int coins, int streak, String streakLabel) {
    return '+$coins moedas • Sequência de $streak $streakLabel';
  }

  @override
  String get dailyBonusStreakLabelOne => 'dia';

  @override
  String get dailyBonusStreakLabelMany => 'dias';

  @override
  String get dailyGoalReachedToast => 'Meta diária atingida!';

  @override
  String dailyGoalBonusCoins(String coins) {
    return '+$coins moedas de bônus';
  }

  @override
  String get profileEditNameTitle => 'Editar nome';

  @override
  String get profileEditNameHint => 'Seu nome';

  @override
  String get profileSave => 'Salvar';

  @override
  String get profileNameUpdated => '✅ Nome atualizado';

  @override
  String get profileLanguageTitle => 'Idioma';

  @override
  String get profileLanguageSubtitle => 'Español / English / Português';

  @override
  String get profileLanguageDialogTitle => 'Selecione o idioma';

  @override
  String get profileLanguageEs => '🇲🇽  Español';

  @override
  String get profileLanguageEn => '🇺🇸  English';

  @override
  String get profileLanguagePt => '🇧🇷  Português';

  @override
  String get profileLanguageAuto => 'Automático (dispositivo)';

  @override
  String get versionUpdateTitle => 'Atualização necessária!';

  @override
  String get versionUpdateBody =>
      'Para continuar ganhando dinheiro com o JUEGALO você precisa instalar a versão mais recente. Ela traz melhorias e mais formas de ganhar!';

  @override
  String get versionUpdateButton => 'Atualizar agora';

  @override
  String get versionUpdateNote =>
      'A atualização é gratuita e leva apenas alguns segundos.';

  @override
  String get versionNewAvailable => '🚀 Nova versão disponível';

  @override
  String get rankingPos1 => '1º Lugar';

  @override
  String get rankingPos2 => '2º Lugar';

  @override
  String get rankingPos3 => '3º Lugar';

  @override
  String get rankingTop50 => 'TOP 50';

  @override
  String get rankingTop3Label => 'TOP 3';

  @override
  String get rankingThisWeek => 'esta semana';

  @override
  String rankingStreakDays(int days) {
    return '$days dias consecutivos';
  }

  @override
  String get rankingCelebFirst => 'Primeiro lugar!';

  @override
  String get rankingCelebSecond => 'Segundo lugar!';

  @override
  String get rankingCelebThird => 'Terceiro lugar!';

  @override
  String get rankingCelebSubtitle =>
      'Na semana passada você foi um\ndos melhores jogadores.';

  @override
  String get rankingCelebCoinsLabel => 'moedas creditadas';

  @override
  String get rankingCelebButton => 'Incrível! 🎉';

  @override
  String get rankingInfoTitle => 'Como funciona o ranking?';

  @override
  String get rankingInfoSubtitle =>
      'Seja um dos melhores jogadores da semana\ne ganhe recompensas em moedas.';

  @override
  String get rankingInfoFirst => 'Primeiro lugar';

  @override
  String get rankingInfoFirstDesc =>
      'O jogador com mais moedas acumuladas na semana ganha';

  @override
  String get rankingInfoSecond => 'Segundo lugar';

  @override
  String get rankingInfoSecondDesc =>
      'Segundo lugar no fechamento semanal ganha';

  @override
  String get rankingInfoThird => 'Terceiro lugar';

  @override
  String get rankingInfoThirdDesc =>
      'Terceiro lugar no fechamento semanal ganha';

  @override
  String get rankingInfoHowToEarn => '💡 Como acumular moedas?';

  @override
  String get rankingInfoTipGames => 'Instale jogos e complete missões';

  @override
  String get rankingInfoTipSurveys => 'Complete pesquisas diárias';

  @override
  String get rankingInfoTipVideos => 'Assista até 20 vídeos por dia';

  @override
  String get rankingInfoTipStreak =>
      'Mantenha sua sequência diária para bônus extras';

  @override
  String get rankingInfoGotIt => 'Entendi!';

  @override
  String get rankingLastWinnersTitle => '🏆  VENCEDORES DA SEMANA PASSADA';

  @override
  String get rankingLastWinnersPrize => 'prêmio';

  @override
  String get txHistoryTitle => 'Histórico completo';

  @override
  String get txFilterAll => 'Todos';

  @override
  String get txFilterVideos => 'Vídeos';

  @override
  String get txFilterSurveys => 'Pesquisas';

  @override
  String get txFilterBonus => 'Bônus';

  @override
  String get txFilterCashout => 'Saques';

  @override
  String get txGroupToday => 'Hoje';

  @override
  String get txGroupYesterday => 'Ontem';

  @override
  String get txGroupThisWeek => 'Esta semana';

  @override
  String get txGroupThisMonth => 'Este mês';

  @override
  String get txGroupOlder => 'Anterior';

  @override
  String get txLoadMore => 'Carregar mais';

  @override
  String get txEmpty => 'Sem transações ainda';

  @override
  String get txEmptyFilter => 'Sem transações deste tipo';

  @override
  String get txSeeAll => 'Ver tudo';
}
