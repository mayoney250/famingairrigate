// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Faminga Irrigation';

  @override
  String get welcomeBack => 'Bienvenue!';

  @override
  String get signInToManage =>
      'Connectez-vous pour gérer vos systèmes d\'irrigation';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Entrez votre email';

  @override
  String get password => 'Mot de passe';

  @override
  String get enterPassword => 'Entrez votre mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get login => 'Connexion';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte? ';

  @override
  String get register => 'S\'inscrire';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get joinFaminga => 'Rejoignez Faminga';

  @override
  String get startManaging =>
      'Commencez à gérer votre irrigation intelligemment';

  @override
  String get firstName => 'Prénom';

  @override
  String get enterFirstName => 'Entrez votre prénom';

  @override
  String get lastName => 'Nom de famille';

  @override
  String get enterLastName => 'Entrez votre nom de famille';

  @override
  String get phoneNumber => 'Numéro de téléphone (Optionnel)';

  @override
  String get enterPhoneNumber => 'Entrez votre numéro de téléphone';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get reEnterPassword => 'Ressaisissez votre mot de passe';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte? ';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get enterEmailForReset =>
      'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get irrigation => 'Irrigation';

  @override
  String get fields => 'Champs';

  @override
  String get sensors => 'Capteurs';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get welcomeUser => 'Bienvenue!';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get overview => 'Aperçu';

  @override
  String get recentActivities => 'Activités récentes';

  @override
  String get activeSystems => 'Systèmes actifs';

  @override
  String get totalFields => 'Total des champs';

  @override
  String get waterSaved => 'Eau économisée';

  @override
  String get activeSensors => 'Capteurs actifs';

  @override
  String get irrigationSystems => 'Systèmes d\'irrigation';

  @override
  String get addSystem => 'Ajouter un système';

  @override
  String get noIrrigationSystems => 'Aucun système d\'irrigation';

  @override
  String get addFirstSystem =>
      'Ajoutez votre premier système d\'irrigation pour commencer';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get type => 'Type';

  @override
  String get source => 'Source';

  @override
  String get mode => 'Mode';

  @override
  String get automated => 'Automatisé';

  @override
  String get manual => 'Manuel';

  @override
  String get waterUsed => 'Eau utilisée';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get loading => 'Chargement...';

  @override
  String get refresh => 'Actualiser';

  @override
  String get notifications => 'Notifications';

  @override
  String get accountCreatedSuccess =>
      'Compte créé avec succès. Veuillez vérifier votre email pour vérifier votre compte.';

  @override
  String get emailSent => 'Email envoyé';

  @override
  String get passwordResetSent =>
      'Le lien de réinitialisation du mot de passe a été envoyé à votre email. Veuillez vérifier votre boîte de réception.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get update => 'Mettre à jour';

  @override
  String get language => 'Langue';

  @override
  String get startNow => 'Commencer maintenant';

  @override
  String get goToFields => 'Aller aux champs';

  @override
  String get noFieldsFound => 'Aucun champ trouvé.';

  @override
  String get systemStatus => 'État du système';

  @override
  String get nextScheduleCycle => 'Prochain cycle programmé';

  @override
  String get weeklyPerformance => 'Performance hebdomadaire';

  @override
  String get soilMoisture => 'Humidité du sol';

  @override
  String get averageToday => 'Moyenne aujourd\'hui';

  @override
  String get noScheduledIrrigations => 'Aucune irrigation programmée';

  @override
  String get startIrrigationManually =>
      'Démarrer l\'irrigation manuellement ou créer un calendrier';

  @override
  String get startCycleManually => 'DÉMARRER LE CYCLE MANUELLEMENT';

  @override
  String get waterUsage => 'Utilisation d\'eau';

  @override
  String get litersThisWeek => 'Litres cette semaine';

  @override
  String get kshSaved => 'KSh économisés';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get noFieldsTitle => 'Aucun champ trouvé';

  @override
  String get noFieldsMessage =>
      'Vous n\'avez aucun champ enregistré. Veuillez d\'abord créer un champ pour démarrer l\'irrigation manuelle.';

  @override
  String get alerts => 'Alertes';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get noAlertsYet => 'Aucune alerte pour le moment';

  @override
  String get justNow => 'À l\'instant';

  @override
  String minutesAgo(int minutes) {
    return 'Il y a ${minutes}min';
  }

  @override
  String hoursAgo(int hours) {
    return 'Il y a ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'Il y a ${days}j';
  }

  @override
  String get manualStart => 'Démarrage manuel';

  @override
  String get farmInfo => 'Info de la ferme';

  @override
  String get scheduled => 'Programmé';

  @override
  String get pleaseEnterFirstName => 'Please enter your first name';

  @override
  String get pleaseEnterLastName => 'Please enter your last name';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get province => 'Province';

  @override
  String get district => 'District';

  @override
  String get chooseProvince => 'Choose a province';

  @override
  String get chooseDistrict => 'Choose a district';

  @override
  String get chooseProvinceFirst => 'Choose a province first';

  @override
  String get addressOptional => 'Address (optional)';

  @override
  String get addressHint => 'e.g., Village, Cell, Sector';

  @override
  String get addressTooShort => 'Address too short';

  @override
  String get addressTooLong => 'Address too long';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get failedToSendResetEmail => 'Failed to send reset email';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get verificationEmailSentTo => 'We\'ve sent a verification email to:';

  @override
  String get nextSteps => 'Next Steps:';

  @override
  String get checkEmailInbox => '1. Check your email inbox';

  @override
  String get lookForFirebaseEmail => '2. Look for an email from Firebase';

  @override
  String get checkSpamFolder => '3. Check your spam/junk folder';

  @override
  String get clickVerificationLink => '4. Click the verification link';

  @override
  String get returnAndClickVerified =>
      '5. Return here and click \"I\'ve Verified\"';

  @override
  String get verifiedMyEmail => 'I\'ve Verified My Email';

  @override
  String get resendVerificationEmail => 'Resend Verification Email';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get errorSendingEmail => 'Error sending email';

  @override
  String get emailNotVerifiedYet =>
      'Email not verified yet. Please check your email and click the verification link.';

  @override
  String get errorCheckingVerification => 'Error checking verification';

  @override
  String get verificationEmailSent =>
      'Verification email sent! Please check your inbox and spam folder.';
}
