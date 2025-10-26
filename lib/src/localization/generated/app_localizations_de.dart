// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get registerTitle => 'Willkommen bei twonly!';

  @override
  String get registerSlogan =>
      'twonly, eine private und sichere Möglichkeit um mit Freunden in Kontakt zu bleiben.';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei twonly!';

  @override
  String get onboardingWelcomeBody =>
      'Erlebe eine private und sichere Möglichkeit mit Freunden in Kontakt zu bleiben, indem du spontane Bilder teilst.';

  @override
  String get onboardingE2eTitle => 'Unbekümmert teilen';

  @override
  String get onboardingE2eBody =>
      'Genieße durch die Ende-zu-Ende-Verschlüsselung die Gewissheit, dass nur du und deine Freunde die geteilten Momente sehen können.';

  @override
  String get onboardingFocusTitle =>
      'Fokussiere dich auf das Teilen von Momenten';

  @override
  String get onboardingFocusBody =>
      'Verabschiede dich von süchtig machenden Funktionen! twonly wurde für das Teilen von Momenten ohne nutzlose Ablenkungen oder Werbung entwickelt.';

  @override
  String get onboardingSendTwonliesTitle => 'twonlies senden';

  @override
  String get onboardingSendTwonliesBody =>
      'Teile Momente sicher mit deinem Partner. twonly stellt sicher, dass nur dein Partner sie öffnen kann, sodass deine Momente mit deinem Partner eine two(o)nly Sache bleiben!';

  @override
  String get onboardingNotProductTitle => 'Du bist nicht das Produkt!';

  @override
  String get onboardingNotProductBody =>
      'twonly wird durch Spenden und ein optionales Abonnement finanziert. Deine Daten werden niemals verkauft.';

  @override
  String get onboardingBuyOneGetTwoTitle => 'Kaufe eins, bekomme zwei';

  @override
  String get onboardingBuyOneGetTwoBody =>
      'twonly benötigt immer mindestens zwei Personen, daher erhältst du beim Kauf eine zweite kostenlose Lizenz für deinen twonly-Partner.';

  @override
  String get onboardingGetStartedTitle => 'Auf geht\'s';

  @override
  String get onboardingGetStartedBody =>
      'Du kannst twonly kostenlos im Preview-Modus testen. In diesem Modus kannst du von anderen gefunden werden und Bilder oder Videos empfangen, aber du kannst selbst keine senden.';

  @override
  String get onboardingTryForFree => 'Jetzt registrieren';

  @override
  String get registerUsernameSlogan =>
      'Bitte wähle einen Benutzernamen, damit dich andere finden können!';

  @override
  String get registerUsernameDecoration => 'Benutzername';

  @override
  String get registerUsernameLimits =>
      'Der Benutzername muss mindestens 3 Zeichen lang sein.';

  @override
  String get registerSubmitButton => 'Jetzt registrieren!';

  @override
  String get registerTwonlyCodeText =>
      'Hast du einen twonly-Code erhalten? Dann löse ihn entweder direkt hier oder später ein!';

  @override
  String get registerTwonlyCodeLabel => 'twonly-Code';

  @override
  String get newMessageTitle => 'Neue Nachricht';

  @override
  String get chatsTapToSend => 'Klicke, um dein erstes Bild zu teilen.';

  @override
  String get cameraPreviewSendTo => 'Senden an';

  @override
  String get shareImageTitle => 'Teilen mit';

  @override
  String get shareImageBestFriends => 'Beste Freunde';

  @override
  String get shareImagePinnedContacts => 'Angeheftet';

  @override
  String get shareImagedEditorSendImage => 'Senden';

  @override
  String get shareImagedEditorShareWith => 'Teilen mit';

  @override
  String get shareImagedEditorSaveImage => 'Speichern';

  @override
  String get shareImagedEditorSavedImage => 'Gespeichert';

  @override
  String get shareImageSearchAllContacts => 'Alle Kontakte durchsuchen';

  @override
  String get shareImagedSelectAll => 'Alle auswählen';

  @override
  String get startNewChatTitle => 'Kontakt wählen';

  @override
  String get startNewChatNewContact => 'Neuer Kontakt';

  @override
  String get startNewChatYourContacts => 'Deine Kontakte';

  @override
  String get shareImageAllUsers => 'Alle Kontakte';

  @override
  String get shareImageAllTwonlyWarning =>
      'twonlies können nur an verifizierte Kontakte gesendet werden!';

  @override
  String get shareImageUserNotVerified => 'Benutzer ist nicht verifiziert';

  @override
  String get shareImageUserNotVerifiedDesc =>
      'twonlies können nur an verifizierte Nutzer gesendet werden. Um einen Nutzer zu verifizieren, gehe auf sein Profil und auf „Sicherheitsnummer verifizieren“.';

  @override
  String get shareImageShowArchived => 'Archivierte Benutzer anzeigen';

  @override
  String get searchUsernameInput => 'Benutzername';

  @override
  String get searchUsernameTitle => 'Benutzernamen suchen';

  @override
  String get searchUserNamePreview =>
      'Um dich und andere twonly Benutzer vor Spam und Missbrauch zu schützen, ist es nicht möglich, im Preview-Modus nach anderen Personen zu suchen. Andere Benutzer können dich finden und deren Anfragen werden dann hier angezeigt!';

  @override
  String get selectSubscription => 'Abo auswählen';

  @override
  String get searchUserNamePending => 'Ausstehend';

  @override
  String get searchUserNameBlockUserTooltip =>
      'Benutzer ohne Benachrichtigung blockieren.';

  @override
  String get searchUserNameRejectUserTooltip =>
      'Die Anfrage ablehnen und den Anfragenden informieren.';

  @override
  String get searchUserNameArchiveUserTooltip =>
      'Benutzer archivieren. Du wirst informiert sobald er deine Anfrage akzeptiert.';

  @override
  String get searchUsernameNotFound => 'Benutzername nicht gefunden';

  @override
  String searchUsernameNotFoundBody(Object username) {
    return 'Es wurde kein Benutzer mit dem Benutzernamen \"$username\" gefunden.';
  }

  @override
  String get searchUsernameNewFollowerTitle => 'Folgeanfragen';

  @override
  String get searchUsernameQrCodeBtn => 'QR-Code scannen';

  @override
  String get chatListViewSearchUserNameBtn =>
      'Füge deinen ersten twonly-Kontakt hinzu!';

  @override
  String get chatListViewSendFirstTwonly => 'Sende dein erstes twonly!';

  @override
  String get chatListDetailInput => 'Nachricht eingeben';

  @override
  String get userDeletedAccount => 'Der Nutzer hat sein Konto gelöscht.';

  @override
  String get contextMenuUserProfile => 'Userprofil';

  @override
  String get contextMenuVerifyUser => 'Verifizieren';

  @override
  String get contextMenuArchiveUser => 'Archivieren';

  @override
  String get contextMenuUndoArchiveUser => 'Archivierung aufheben';

  @override
  String get contextMenuOpenChat => 'Chat';

  @override
  String get contextMenuPin => 'Anheften';

  @override
  String get contextMenuUnpin => 'Lösen';

  @override
  String get mediaViewerAuthReason =>
      'Bitte authentifiziere dich, um diesen twonly zu sehen!';

  @override
  String get mediaViewerTwonlyTapToOpen => 'Tippe um den twonly zu öffnen!';

  @override
  String get messageSendState_Received => 'Empfangen';

  @override
  String get messageSendState_Opened => 'Geöffnet';

  @override
  String get messageSendState_Send => 'Gesendet';

  @override
  String get messageSendState_Sending => 'Wird gesendet';

  @override
  String get messageSendState_TapToLoad => 'Tippe zum Laden';

  @override
  String get messageSendState_Loading => 'Herunterladen';

  @override
  String get messageStoredInGallery => 'Gespeichert';

  @override
  String get messageReopened => 'Erneut geöffnet';

  @override
  String get imageEditorDrawOk => 'Zeichnung machen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsChats => 'Chats';

  @override
  String get settingsPreSelectedReactions => 'Vorgewählte Reaktions-Emojis';

  @override
  String get settingsPreSelectedReactionsError =>
      'Es können maximal 12 Reaktionen ausgewählt werden.';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsStorageData => 'Daten und Speicher';

  @override
  String get settingsStorageDataStoreInGTitle => 'In der Galerie speichern';

  @override
  String get settingsStorageDataStoreInGSubtitle =>
      'Speichere Bilder zusätzlich in der Systemgalerie.';

  @override
  String get settingsStorageDataMediaAutoDownload =>
      'Automatischer Mediendownload';

  @override
  String get settingsStorageDataAutoDownMobile => 'Bei Nutzung mobiler Daten';

  @override
  String get settingsStorageDataAutoDownWifi => 'Bei Nutzung von WLAN';

  @override
  String get settingsProfileCustomizeAvatar => 'Avatar anpassen';

  @override
  String get settingsProfileEditDisplayName => 'Anzeigename';

  @override
  String get settingsProfileEditDisplayNameNew => 'Neuer Anzeigename';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsSubscription => 'Abonnement';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get settingsPrivacy => 'Datenschutz';

  @override
  String get settingsPrivacyBlockUsers => 'Benutzer blockieren';

  @override
  String get settingsPrivacyBlockUsersDesc =>
      'Blockierte Benutzer können nicht mit dir kommunizieren. Du kannst einen blockierten Benutzer jederzeit wieder entsperren.';

  @override
  String settingsPrivacyBlockUsersCount(Object len) {
    return '$len Kontakt(e)';
  }

  @override
  String get settingsNotification => 'Benachrichtigung';

  @override
  String get settingsNotifyTroubleshooting => 'Fehlersuche';

  @override
  String get settingsNotifyTroubleshootingDesc =>
      'Hier klicken, wenn Probleme beim Empfang von Push-Benachrichtigungen auftreten.';

  @override
  String get settingsNotifyTroubleshootingNoProblem =>
      'Kein Problem festgestellt';

  @override
  String get settingsNotifyTroubleshootingNoProblemDesc =>
      'Klicke auf OK, um eine Testbenachrichtigung zu erhalten. Wenn du auch nach 10 Minuten warten keine Nachricht erhältst, sende uns bitte dein Diagnoseprotokoll unter Einstellungen > Hilfe > Diagnoseprotokoll, damit wir uns das Problem ansehen können.';

  @override
  String get settingsHelp => 'Hilfe';

  @override
  String get settingsHelpDiagnostics => 'Diagnoseprotokoll';

  @override
  String get settingsHelpFAQ => 'FAQ';

  @override
  String get feedbackTooltip => 'Feedback zur Verbesserung von twonly geben.';

  @override
  String get settingsHelpContactUs => 'Kontaktiere uns';

  @override
  String get settingsHelpVersion => 'Version';

  @override
  String get settingsHelpLicenses => 'Lizenzen (Source-Code)';

  @override
  String get settingsHelpCredits => 'Lizenzen (Bilder)';

  @override
  String get settingsHelpImprint => 'Impressum & Datenschutzrichtlinie';

  @override
  String get contactUsFaq => 'FAQ schon gelesen?';

  @override
  String get contactUsEmojis => 'Wie fühlst du dich? (optional)';

  @override
  String get contactUsSelectOption => 'Bitte wähle eine Option';

  @override
  String get contactUsReason => 'Sag uns, warum du uns kontaktierst';

  @override
  String get contactUsMessage =>
      'Wenn du eine Antwort erhalten möchtest, füge bitte deine E-Mail-Adresse hinzu, damit wir dich kontaktieren können.';

  @override
  String get contactUsYourMessage => 'Deine Nachricht';

  @override
  String get contactUsMessageTitle => 'Erzähl uns, was los ist';

  @override
  String get contactUsReasonNotWorking => 'Etwas funktioniert nicht';

  @override
  String get contactUsReasonFeatureRequest => 'Funktionsanfrage';

  @override
  String get contactUsReasonQuestion => 'Frage';

  @override
  String get contactUsReasonFeedback => 'Feedback';

  @override
  String get contactUsReasonOther => 'Sonstiges';

  @override
  String get contactUsIncludeLog => 'Debug-Protokoll anhängen.';

  @override
  String get contactUsWhatsThat => 'Was ist das?';

  @override
  String get contactUsLastWarning =>
      'Dies sind die Informationen, die an uns gesendet werden. Bitte prüfen Sie sie und klicke dann auf „Abschicken“.';

  @override
  String get contactUsSuccess => 'Feedback erfolgreich übermittelt!';

  @override
  String get contactUsShortcut => 'Feedback-Symbol ausblenden';

  @override
  String get settingsHelpTerms => 'Nutzungsbedingungen';

  @override
  String get settingsAppearanceTheme => 'Theme';

  @override
  String get settingsAccountDeleteAccount => 'Konto löschen';

  @override
  String settingsAccountDeleteAccountWithBallance(Object credit) {
    return 'Im nächsten Schritt kannst du auswählen, was du mit dem Restguthaben ($credit) machen willst.';
  }

  @override
  String get settingsAccountDeleteAccountNoBallance =>
      'Wenn du dein Konto gelöscht hast, gibt es keinen Weg zurück.';

  @override
  String get settingsAccountDeleteAccountNoInternet =>
      'Zum Löschen deines Accounts ist eine Internetverbindung erforderlich.';

  @override
  String get settingsAccountDeleteModalTitle => 'Bist du sicher?';

  @override
  String get settingsAccountDeleteModalBody =>
      'Dein Konto wird gelöscht. Es gibt keine Möglichkeit, es wiederherzustellen.';

  @override
  String get contactVerifyNumberTitle => 'Sicherheitsnummer verifizieren';

  @override
  String get contactVerifyNumberTapToScan => 'Zum Scannen tippen';

  @override
  String get contactVerifyNumberMarkAsVerified => 'Als verifiziert markieren';

  @override
  String get contactVerifyNumberClearVerification => 'Verifizierung aufheben';

  @override
  String contactVerifyNumberLongDesc(Object username) {
    return 'Um die Ende-zu-Ende-Verschlüsselung mit $username zu verifizieren, vergleiche die Zahlen mit ihrem Gerät. Die Person kann auch deinen Code mit ihrem Gerät scannen.';
  }

  @override
  String get contactNickname => 'Spitzname';

  @override
  String get contactNicknameNew => 'Neuer Spitzname';

  @override
  String get deleteAllContactMessages => 'Textnachrichten löschen';

  @override
  String deleteAllContactMessagesBody(Object username) {
    return 'Dadurch werden alle Nachrichten, ausgenommen gespeicherte Mediendateien, in deinem Chat mit $username gelöscht. Dies löscht NICHT die auf dem Gerät von $username gespeicherten Nachrichten!';
  }

  @override
  String get contactBlock => 'Blockieren';

  @override
  String contactBlockTitle(Object username) {
    return 'Blockiere $username';
  }

  @override
  String get contactBlockBody =>
      'Ein blockierter Benutzer kann dir keine Nachrichten mehr senden, und sein Profil ist nicht mehr sichtbar. Um die Blockierung eines Benutzers aufzuheben, navigiere einfach zu Einstellungen > Datenschutz > Blockierte Benutzer.';

  @override
  String get contactRemove => 'Benutzer löschen';

  @override
  String contactRemoveTitle(Object username) {
    return '$username löschen?';
  }

  @override
  String get contactRemoveBody =>
      'Entferne den Benutzer und lösche den Chat sowie alle zugehörigen Mediendateien dauerhaft. Dadurch wird auch DEIN KONTO VON DEM TELEFON DEINES KONTAKTS gelöscht.';

  @override
  String get undo => 'Rückgängig';

  @override
  String get redo => 'Wiederholen';

  @override
  String get next => 'Weiter';

  @override
  String get submit => 'Abschicken';

  @override
  String get close => 'Schließen';

  @override
  String get disable => 'Deaktiviern';

  @override
  String get enable => 'Aktivieren';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get now => 'Jetzt';

  @override
  String get you => 'Du';

  @override
  String get minutesShort => 'Min.';

  @override
  String get image => 'Bild';

  @override
  String get video => 'Video';

  @override
  String get react => 'Reagieren';

  @override
  String get reply => 'Antworten';

  @override
  String get copy => 'Kopieren';

  @override
  String get delete => 'Löschen';

  @override
  String get info => 'Info';

  @override
  String get ok => 'Ok';

  @override
  String get switchFrontAndBackCamera =>
      'Zwischen Front- und Rückkamera wechseln.';

  @override
  String get addTextItem => 'Text';

  @override
  String get protectAsARealTwonly => 'Als echtes twonly senden!';

  @override
  String get addDrawing => 'Zeichnung';

  @override
  String get addEmoji => 'Emoji';

  @override
  String get toggleFlashLight => 'Taschenlampe umschalten';

  @override
  String get toggleHighQuality => 'Bessere Auflösung umschalten';

  @override
  String get userFound => 'Benutzer gefunden';

  @override
  String get userFoundBody => 'Möchtest du eine Folgeanfrage stellen?';

  @override
  String searchUsernameNotFoundLong(Object username) {
    return '\"$username\" ist kein twonly-Benutzer. Bitte überprüfe den Benutzernamen und versuche es erneut.';
  }

  @override
  String get errorUnknown =>
      'Ein unerwarteter Fehler ist aufgetreten. Bitte versuche es später erneut.';

  @override
  String get errorBadRequest =>
      'Die Anfrage konnte vom Server aufgrund einer fehlerhaften Syntax nicht verstanden werden. Bitte überprüfe deine Eingabe und versuche es erneut.';

  @override
  String get errorTooManyRequests =>
      'Du hast in kurzer Zeit zu viele Anfragen gestellt. Bitte warte einen Moment, bevor du es erneut versuchst.';

  @override
  String get errorInternalError =>
      'Der Server ist derzeit nicht verfügbar. Bitte versuche es später erneut.';

  @override
  String get errorInvalidInvitationCode =>
      'Der von dir angegebene Einladungscode ist ungültig. Bitte überprüfe den Code und versuche es erneut.';

  @override
  String get errorUsernameAlreadyTaken =>
      'Der Benutzername, den du verwenden möchtest, ist bereits vergeben. Bitte wähle einen anderen Benutzernamen.';

  @override
  String get errorSignatureNotValid =>
      'Die bereitgestellte Signatur ist nicht gültig. Bitte überprüfe deine Anmeldeinformationen und versuche es erneut.';

  @override
  String get errorUsernameNotFound =>
      'Der eingegebene Benutzername existiert nicht. Bitte überprüfe die Schreibweise oder erstelle ein neues Konto.';

  @override
  String get errorUsernameNotValid =>
      'Der von dir angegebene Benutzername entspricht nicht den erforderlichen Kriterien. Bitte wähle einen gültigen Benutzernamen.';

  @override
  String get errorInvalidPublicKey =>
      'Der von dir angegebene öffentliche Schlüssel ist ungültig. Bitte überprüfe den Schlüssel und versuche es erneut.';

  @override
  String get errorSessionAlreadyAuthenticated =>
      'Du bist bereits angemeldet. Bitte melde dich ab, wenn du dich mit einem anderen Konto anmelden möchtest.';

  @override
  String get errorSessionNotAuthenticated =>
      'Deine Sitzung ist nicht authentifiziert. Bitte melde dich an, um fortzufahren.';

  @override
  String get errorOnlyOneSessionAllowed =>
      'Es ist nur eine aktive Sitzung pro Benutzer erlaubt. Bitte melde dich von anderen Geräten ab, um fortzufahren.';

  @override
  String get errorNotEnoughCredit => 'Du hast nicht genügend twonly-Guthaben.';

  @override
  String get errorVoucherInvalid =>
      'Der eingegebene Gutschein-Code ist nicht gültig.';

  @override
  String get errorPlanLimitReached =>
      'Du hast das Limit deines Plans erreicht. Bitte upgrade deinen Plan.';

  @override
  String get errorPlanNotAllowed =>
      'Dieses Feature ist in deinem aktuellen Plan nicht verfügbar.';

  @override
  String get errorPlanUpgradeNotYearly =>
      'Das Upgrade des Plans muss jährlich bezahlt werden, da der aktuelle Plan ebenfalls jährlich abgerechnet wird.';

  @override
  String get upgradeToPaidPlan => 'Upgrade auf einen kostenpflichtigen Plan.';

  @override
  String upgradeToPaidPlanButton(Object planId) {
    return 'Auf $planId upgraden';
  }

  @override
  String partOfPaidPlanOf(Object username) {
    return 'Du bist Teil des bezahlten Plans von $username!';
  }

  @override
  String get year => 'year';

  @override
  String get month => 'month';

  @override
  String get proFeature1 => '✓ Unbegrenzte Medien-Datei-Uploads';

  @override
  String get proFeature2 => '1 zusätzlicher Plus Benutzer';

  @override
  String get proFeature3 => 'Zusatzfunktionen (coming-soon)';

  @override
  String get proFeature4 => 'Cloud-Backup verschlüsselt (coming-soon)';

  @override
  String get familyFeature1 => '✓ Alles von Pro';

  @override
  String get familyFeature2 => '4 zusätzliche Plus Benutzer';

  @override
  String get redeemUserInviteCode => 'Oder löse einen twonly-Code ein.';

  @override
  String get redeemUserInviteCodeTitle => 'twonly-Code einlösen';

  @override
  String get redeemUserInviteCodeSuccess =>
      'Dein Plan wurde erfolgreich angepasst.';

  @override
  String get freeFeature1 => '10 Medien-Datei-Uploads pro Tag';

  @override
  String get plusFeature1 => '✓ Unbegrenzte Medien-Datei-Uploads';

  @override
  String get plusFeature2 => 'Zusatzfunktionen (coming-soon)';

  @override
  String get transactionHistory => 'Transaktionshistorie';

  @override
  String get manageSubscription => 'Abonnement verwalten';

  @override
  String get nextPayment => 'Nächste Zahlung';

  @override
  String get currentBalance => 'Dein Guthaben';

  @override
  String get manageAdditionalUsers => 'Zusätzliche Benutzer verwalten';

  @override
  String get open => 'Offene';

  @override
  String get createOrRedeemVoucher => 'Gutschein erstellen oder einlösen';

  @override
  String get createVoucher => 'Gutschein kaufen';

  @override
  String get createVoucherDesc =>
      'Wähle den Wert des Gutscheins. Der Wert des Gutschein wird von deinem twonly-Guthaben abgezogen.';

  @override
  String get redeemVoucher => 'Gutschein einlösen';

  @override
  String get openVouchers => 'Offene Gutscheine';

  @override
  String get voucherCreated => 'Gutschein wurde erstellt';

  @override
  String get voucherRedeemed => 'Gutschein eingelöst';

  @override
  String get enterVoucherCode => 'Gutschein Code eingeben';

  @override
  String get requestedVouchers => 'Beantragte Gutscheine';

  @override
  String get redeemedVouchers => 'Eingelöste Gutscheine';

  @override
  String get buy => 'Kaufen';

  @override
  String subscriptionRefund(Object refund) {
    return 'Wenn du ein Upgrade durchführst, erhältst du eine Rückerstattung von $refund für dein aktuelles Abonnement.';
  }

  @override
  String get transactionCash => 'Bargeldtransaktion';

  @override
  String get transactionPlanUpgrade => 'Planupgrade';

  @override
  String get transactionRefund => 'Rückerstattung';

  @override
  String get transactionThanksForTesting => 'Danke fürs Testen';

  @override
  String get transactionUnknown => 'Unbekannte Transaktion';

  @override
  String get transactionVoucherCreated => 'Gutschein erstellt';

  @override
  String get transactionVoucherRedeemed => 'Gutschein eingelöst';

  @override
  String get transactionAutoRenewal => 'Automatische Verlängerung';

  @override
  String get checkoutOptions => 'Optionen';

  @override
  String get refund => 'Rückerstattung';

  @override
  String get checkoutPayYearly => 'Jährlich bezahlen';

  @override
  String get checkoutTotal => 'Gesamt';

  @override
  String get selectPaymentMethod => 'Zahlungsmethode auswählen';

  @override
  String get twonlyCredit => 'twonly-Guthaben';

  @override
  String get notEnoughCredit => 'Du hast nicht genügend Guthaben!';

  @override
  String get chargeCredit => 'Guthaben aufladen';

  @override
  String get autoRenewal => 'Automatische Verlängerung';

  @override
  String get autoRenewalDesc => 'Du kannst dies jederzeit ändern.';

  @override
  String get autoRenewalLongDesc =>
      'Wenn dein Abonnement ausläuft, wirst du automatisch auf den Preview-Plan zurückgestuft. Wenn du die automatische Verlängerung aktivierst, vergewissere dich bitte, dass du über genügend Guthaben für die automatische Erneuerung verfügst.  Wir werden dich rechtzeitig vor der automatischen Erneuerung benachrichtigen.';

  @override
  String get planSuccessUpgraded => 'Dein Plan wurde erfolgreich aktualisiert.';

  @override
  String get checkoutSubmit => 'Kostenpflichtig bestellen';

  @override
  String get additionalUsersList => 'Ihre zusätzlichen Benutzer';

  @override
  String get additionalUsersPlusTokens => 'twonly-Codes für \"Plus\"-Benutzer';

  @override
  String get additionalUsersFreeTokens => 'twonly-Codes für \"Free\"-Benutzer';

  @override
  String get planLimitReached =>
      'Du hast dein Planlimit für heute erreicht. Aktualisiere deinen Plan jetzt, um die Mediendatei zu senden.';

  @override
  String get planNotAllowed =>
      'In deinem aktuellen Plan kannst du keine Mediendateien versenden. Aktualisiere deinen Plan jetzt, um die Mediendatei zu senden.';

  @override
  String get galleryDelete => 'Datei löschen';

  @override
  String get galleryDetails => 'Details anzeigen';

  @override
  String get galleryExport => 'In Galerie exportieren';

  @override
  String get galleryExportSuccess => 'Erfolgreich in der Gallery gespeichert.';

  @override
  String get settingsResetTutorials => 'Tutorials erneut anzeigen';

  @override
  String get settingsResetTutorialsDesc =>
      'Klicke hier, um bereits angezeigte Tutorials erneut anzuzeigen.';

  @override
  String get settingsResetTutorialsSuccess =>
      'Tutorials werden erneut angezeigt.';

  @override
  String get tutorialChatListSearchUsersTitle =>
      'Freunde finden und Freundschaftsanfragen verwalten';

  @override
  String get tutorialChatListSearchUsersDesc =>
      'Wenn du die Benutzernamen deiner Freunde kennst, kannst du sie hier suchen und eine Freundschaftsanfrage senden. Außerdem siehst du hier alle Anfragen von anderen Nutzern, die du annehmen oder blockieren kannst.';

  @override
  String get tutorialChatListContextMenuTitle =>
      'Klicke lange auf den Kontakt, um das Kontextmenü zu öffnen.';

  @override
  String get tutorialChatListContextMenuDesc =>
      'Mit dem Kontextmenü kannst du deine Kontakte anheften, archivieren und verschiedene Aktionen durchführen. Halte dazu einfach den Kontakt lange gedrückt und bewege dann deinen Finger auf die gewünschte Option oder tippe direkt darauf.';

  @override
  String get tutorialChatMessagesVerifyShieldTitle =>
      'Verifiziere deine Kontakte!';

  @override
  String get tutorialChatMessagesVerifyShieldDesc =>
      'twonly nutzt das Signal-Protokoll für eine sichere Ende-zu-Ende Verschlüsselung. Bei der ersten Kontaktaufnahme wird dafür der öffentliche Identitätsschlüssel von deinem Kontakt heruntergeladen. Um sicherzustellen, dass dieser Schlüssel nicht von Dritten ausgetauscht wurde, solltest du ihn mit deinem Freund vergleichen, wenn ihr euch persönlich trefft. Sobald du den Benutzer verifiziert hast, kannst du auch beim verschicken von Bildern und Videos den twonly-Modus aktivieren.';

  @override
  String get tutorialChatMessagesReopenMessageTitle =>
      'Bilder und Videos erneut öffnen';

  @override
  String get tutorialChatMessagesReopenMessageDesc =>
      'Wenn dein Freund dir ein Bild oder Video mit unendlicher Anzeigezeit gesendet hat, kannst du es bis zum Neustart der App jederzeit erneut öffnen. Um dies zu tun, musst du einfach doppelt auf die Nachricht klicken. Dein Freund erhält dann eine Benachrichtigung, dass du das Bild erneut angesehen hast.';

  @override
  String get memoriesEmpty =>
      'Sobald du Bilder oder Videos speicherst, landen sie hier in deinen Erinnerungen.';

  @override
  String get deleteTitle => 'Bist du dir sicher?';

  @override
  String get deleteOkBtn => 'Für mich löschen';

  @override
  String get deleteImageTitle => 'Bist du dir sicher?';

  @override
  String get deleteImageBody => 'Das Bild wird unwiderruflich gelöscht.';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get backupNoticeTitle => 'Kein Backup konfiguriert';

  @override
  String get backupNoticeDesc =>
      'Wenn du dein Gerät wechselst oder verlierst, kann ohne Backup niemand dein Account wiederherstellen. Sichere deshalb deine Daten.';

  @override
  String get backupNoticeLater => 'Später erinnern';

  @override
  String get backupNoticeOpenBackup => 'Backup erstellen';

  @override
  String get backupPending => 'Ausstehend';

  @override
  String get backupFailed => 'Fehlgeschlagen';

  @override
  String get backupSuccess => 'Erfolgreich';

  @override
  String get backupTwonlySafeDesc =>
      'Sichere deine twonly-Identität, da dies die einzige Möglichkeit ist, dein Konto wiederherzustellen, wenn du die App deinstallierst oder dein Handy verlierst.';

  @override
  String get backupServer => 'Server';

  @override
  String get backupMaxBackupSize => 'max. Backup-Größe';

  @override
  String get backupStorageRetention => 'Speicheraufbewahrung';

  @override
  String get backupLastBackupDate => 'Letztes Backup';

  @override
  String get backupLastBackupSize => 'Backup-Größe';

  @override
  String get backupLastBackupResult => 'Ergebnis';

  @override
  String get deleteBackupTitle => 'Bist du sicher?';

  @override
  String get deleteBackupBody =>
      'Ohne ein Backup kannst du dein Benutzerkonto nicht wiederherstellen.';

  @override
  String get backupData => 'Daten-Backup';

  @override
  String get backupDataDesc =>
      'Das Daten-Backup enthält neben deiner twonly-Identität auch alle deine Mediendateien. Dieses Backup ist ebenfalls verschlüsselt, wird jedoch lokal gespeichert. Du musst es dann manuell auf deinen Laptop oder ein Gerät deiner Wahl kopieren.';

  @override
  String get backupInsecurePassword => 'Unsicheres Passwort';

  @override
  String get backupInsecurePasswordDesc =>
      'Das gewählte Passwort ist sehr unsicher und kann daher leicht von Angreifern erraten werden. Bitte wähle ein sicheres Passwort.';

  @override
  String get backupInsecurePasswordOk => 'Trotzdem fortfahren';

  @override
  String get backupInsecurePasswordCancel => 'Erneut versuchen';

  @override
  String get backupTwonlySafeLongDesc =>
      'twonly hat keine zentralen Benutzerkonten. Während der Installation wird ein Schlüsselpaar erstellt, das aus einem öffentlichen und einem privaten Schlüssel besteht. Der private Schlüssel wird nur auf deinem Gerät gespeichert, um ihn vor unbefugtem Zugriff zu schützen. Der öffentliche Schlüssel wird auf den Server hochgeladen und mit deinem gewählten Benutzernamen verknüpft, damit andere dich finden können.\n\ntwonly Safe erstellt regelmäßig ein verschlüsseltes, anonymes Backup deines privaten Schlüssels zusammen mit deinen Kontakten und Einstellungen. Dein Benutzername und das gewählte Passwort reichen aus, um diese Daten auf einem anderen Gerät wiederherzustellen.';

  @override
  String get backupSelectStrongPassword =>
      'Wähle ein sicheres Passwort. Dies ist erforderlich, wenn du dein twonly Safe-Backup wiederherstellen möchtest.';

  @override
  String get password => 'Passwort';

  @override
  String get passwordRepeated => 'Passwort wiederholen';

  @override
  String get passwordRepeatedNotEqual => 'Passwörter stimmen nicht überein.';

  @override
  String get backupPasswordRequirement =>
      'Das Passwort muss mindestens 8 Zeichen lang sein.';

  @override
  String get backupExpertSettings => 'Experteneinstellungen';

  @override
  String get backupEnableBackup => 'Automatische Sicherung aktivieren';

  @override
  String get backupOwnServerDesc =>
      'Speichere dein twonly Safe-Backups auf einem Server deiner Wahl.';

  @override
  String get backupUseOwnServer => 'Server verwenden';

  @override
  String get backupResetServer => 'Standardserver verwenden';

  @override
  String get backupTwonlySaveNow => 'Jetzt speichern';

  @override
  String get twonlySafeRecoverTitle => 'Recovery';

  @override
  String get twonlySafeRecoverDesc =>
      'If you have created a backup with twonly Safe, you can restore it here.';

  @override
  String get twonlySafeRecoverBtn => 'Restore backup';

  @override
  String get inviteFriends => 'Freunde einladen';

  @override
  String get inviteFriendsShareBtn => 'Teilen';

  @override
  String inviteFriendsShareText(Object url) {
    return 'Wechseln wir zu twonly: $url';
  }

  @override
  String get appOutdated => 'Deine Version von twonly ist veraltet.';

  @override
  String get appOutdatedBtn => 'Jetzt aktualisieren.';

  @override
  String get doubleClickToReopen => 'Doppelklicken zum\nerneuten Öffnen.';

  @override
  String get retransmissionRequested => 'Wird erneut versucht.';

  @override
  String get testPaymentMethod =>
      'Vielen Dank für dein Interesse an einem kostenpflichtigen Tarif. Die kostenpflichtigen Pläne sind derzeit noch deaktiviert. Sie werden aber bald aktiviert!';

  @override
  String get openChangeLog => 'Changelog automatisch öffnen';

  @override
  String reportUserTitle(Object username) {
    return 'Melde $username';
  }

  @override
  String get reportUserReason => 'Meldegrund';

  @override
  String get reportUser => 'Benutzer melden';

  @override
  String get newDeviceRegistered =>
      'Du hast dich auf einem anderen Gerät angemeldet. Daher wurdest du hier abgemeldet.';

  @override
  String get tabToRemoveEmoji => 'Tippen um zu entfernen';

  @override
  String get quotedMessageWasDeleted =>
      'Die zitierte Nachricht wurde gelöscht.';
}
