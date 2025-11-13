import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to twonly!'**
  String get registerTitle;

  /// No description provided for @registerSlogan.
  ///
  /// In en, this message translates to:
  /// **'twonly, a privacy friendly way to connect with friends through secure, spontaneous image sharing'**
  String get registerSlogan;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to twonly!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Experience a private and secure way to stay in touch with friends by sharing instant pictures.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingE2eTitle.
  ///
  /// In en, this message translates to:
  /// **'Carefree sharing'**
  String get onboardingE2eTitle;

  /// No description provided for @onboardingE2eBody.
  ///
  /// In en, this message translates to:
  /// **'With end-to-end encryption, enjoy the peace of mind that only you and your friends can see the moments you share.'**
  String get onboardingE2eBody;

  /// No description provided for @onboardingFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus on sharing moments'**
  String get onboardingFocusTitle;

  /// No description provided for @onboardingFocusBody.
  ///
  /// In en, this message translates to:
  /// **'Say goodbye to addictive features! twonly was created for sharing moments, free from useless distractions or ads.'**
  String get onboardingFocusBody;

  /// No description provided for @onboardingSendTwonliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Send twonlies'**
  String get onboardingSendTwonliesTitle;

  /// No description provided for @onboardingSendTwonliesBody.
  ///
  /// In en, this message translates to:
  /// **'Share moments securely with your partner. twonly ensures that only your partner can open it, keeping your moments with your partner a two(o)nly thing!'**
  String get onboardingSendTwonliesBody;

  /// No description provided for @onboardingNotProductTitle.
  ///
  /// In en, this message translates to:
  /// **'You are not the product!'**
  String get onboardingNotProductTitle;

  /// No description provided for @onboardingNotProductBody.
  ///
  /// In en, this message translates to:
  /// **'twonly is financed by donations and an optional subscription. Your data will never be sold.'**
  String get onboardingNotProductBody;

  /// No description provided for @onboardingBuyOneGetTwoTitle.
  ///
  /// In en, this message translates to:
  /// **'Buy one get two'**
  String get onboardingBuyOneGetTwoTitle;

  /// No description provided for @onboardingBuyOneGetTwoBody.
  ///
  /// In en, this message translates to:
  /// **'twonly always requires at least two people, which is why you receive a second free license for your twonly partner with your purchase.'**
  String get onboardingBuyOneGetTwoBody;

  /// No description provided for @onboardingGetStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get onboardingGetStartedTitle;

  /// No description provided for @onboardingGetStartedBody.
  ///
  /// In en, this message translates to:
  /// **'You can test twonly free of charge in preview mode. In this mode you can be found by others and receive pictures or videos but you cannot send any yourself.'**
  String get onboardingGetStartedBody;

  /// No description provided for @onboardingTryForFree.
  ///
  /// In en, this message translates to:
  /// **'Try for free'**
  String get onboardingTryForFree;

  /// No description provided for @registerUsernameSlogan.
  ///
  /// In en, this message translates to:
  /// **'Please select a username so others can find you!'**
  String get registerUsernameSlogan;

  /// No description provided for @registerUsernameDecoration.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get registerUsernameDecoration;

  /// No description provided for @registerUsernameLimits.
  ///
  /// In en, this message translates to:
  /// **'Your username must be at least 3 characters long.'**
  String get registerUsernameLimits;

  /// No description provided for @registerSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Register now!'**
  String get registerSubmitButton;

  /// No description provided for @registerTwonlyCodeText.
  ///
  /// In en, this message translates to:
  /// **'Have you received a twonly code? Then redeem it either directly here or later!'**
  String get registerTwonlyCodeText;

  /// No description provided for @registerTwonlyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'twonly-Code'**
  String get registerTwonlyCodeLabel;

  /// No description provided for @newMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessageTitle;

  /// No description provided for @chatsTapToSend.
  ///
  /// In en, this message translates to:
  /// **'Click to send your first image'**
  String get chatsTapToSend;

  /// No description provided for @cameraPreviewSendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get cameraPreviewSendTo;

  /// No description provided for @shareImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with'**
  String get shareImageTitle;

  /// No description provided for @shareImageBestFriends.
  ///
  /// In en, this message translates to:
  /// **'Best friends'**
  String get shareImageBestFriends;

  /// No description provided for @shareImagePinnedContacts.
  ///
  /// In en, this message translates to:
  /// **'Pinnded'**
  String get shareImagePinnedContacts;

  /// No description provided for @shareImagedEditorSendImage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get shareImagedEditorSendImage;

  /// No description provided for @shareImagedEditorShareWith.
  ///
  /// In en, this message translates to:
  /// **'Share with'**
  String get shareImagedEditorShareWith;

  /// No description provided for @shareImagedEditorSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get shareImagedEditorSaveImage;

  /// No description provided for @shareImagedEditorSavedImage.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get shareImagedEditorSavedImage;

  /// No description provided for @shareImageSearchAllContacts.
  ///
  /// In en, this message translates to:
  /// **'Search all contacts'**
  String get shareImageSearchAllContacts;

  /// No description provided for @startNewChatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, username or groupname'**
  String get startNewChatSearchHint;

  /// No description provided for @shareImagedSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get shareImagedSelectAll;

  /// No description provided for @startNewChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Contact'**
  String get startNewChatTitle;

  /// No description provided for @startNewChatNewContact.
  ///
  /// In en, this message translates to:
  /// **'New Contact'**
  String get startNewChatNewContact;

  /// No description provided for @startNewChatYourContacts.
  ///
  /// In en, this message translates to:
  /// **'Your Contacts'**
  String get startNewChatYourContacts;

  /// No description provided for @shareImageAllUsers.
  ///
  /// In en, this message translates to:
  /// **'All contacts'**
  String get shareImageAllUsers;

  /// No description provided for @shareImageAllTwonlyWarning.
  ///
  /// In en, this message translates to:
  /// **'twonlies can only be send to verified contacts!'**
  String get shareImageAllTwonlyWarning;

  /// No description provided for @shareImageUserNotVerified.
  ///
  /// In en, this message translates to:
  /// **'User is not verified'**
  String get shareImageUserNotVerified;

  /// No description provided for @shareImageUserNotVerifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'twonlies can only be sent to verified users. To verify a user, go to their profile and to verify security number.'**
  String get shareImageUserNotVerifiedDesc;

  /// No description provided for @shareImageShowArchived.
  ///
  /// In en, this message translates to:
  /// **'Show archived users'**
  String get shareImageShowArchived;

  /// No description provided for @searchUsernameInput.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get searchUsernameInput;

  /// No description provided for @searchUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Search username'**
  String get searchUsernameTitle;

  /// No description provided for @searchUserNamePreview.
  ///
  /// In en, this message translates to:
  /// **'To protect you and other twonly users from spam and abuse, it is not possible to search for other people in preview mode. Other users can find you and their requests will be displayed here!'**
  String get searchUserNamePreview;

  /// No description provided for @selectSubscription.
  ///
  /// In en, this message translates to:
  /// **'Select subscription'**
  String get selectSubscription;

  /// No description provided for @searchUserNamePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get searchUserNamePending;

  /// No description provided for @searchUserNameBlockUserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Block the user without informing.'**
  String get searchUserNameBlockUserTooltip;

  /// No description provided for @searchUserNameRejectUserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reject the request and let the requester know.'**
  String get searchUserNameRejectUserTooltip;

  /// No description provided for @searchUserNameArchiveUserTooltip.
  ///
  /// In en, this message translates to:
  /// **'Archive the user. He will appear again as soon as he accepts your request.'**
  String get searchUserNameArchiveUserTooltip;

  /// No description provided for @searchUsernameNotFound.
  ///
  /// In en, this message translates to:
  /// **'Username not found'**
  String get searchUsernameNotFound;

  /// No description provided for @searchUsernameNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'There is no user with the username \"{username}\" registered'**
  String searchUsernameNotFoundBody(Object username);

  /// No description provided for @searchUsernameNewFollowerTitle.
  ///
  /// In en, this message translates to:
  /// **'Follow requests'**
  String get searchUsernameNewFollowerTitle;

  /// No description provided for @searchUsernameQrCodeBtn.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get searchUsernameQrCodeBtn;

  /// No description provided for @chatListViewSearchUserNameBtn.
  ///
  /// In en, this message translates to:
  /// **'Add your first twonly contact!'**
  String get chatListViewSearchUserNameBtn;

  /// No description provided for @chatListViewSendFirstTwonly.
  ///
  /// In en, this message translates to:
  /// **'Send your first twonly!'**
  String get chatListViewSendFirstTwonly;

  /// No description provided for @chatListDetailInput.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatListDetailInput;

  /// No description provided for @userDeletedAccount.
  ///
  /// In en, this message translates to:
  /// **'The user has deleted its account.'**
  String get userDeletedAccount;

  /// No description provided for @contextMenuUserProfile.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get contextMenuUserProfile;

  /// No description provided for @contextMenuVerifyUser.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get contextMenuVerifyUser;

  /// No description provided for @contextMenuArchiveUser.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get contextMenuArchiveUser;

  /// No description provided for @contextMenuUndoArchiveUser.
  ///
  /// In en, this message translates to:
  /// **'Undo archiving'**
  String get contextMenuUndoArchiveUser;

  /// No description provided for @contextMenuOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get contextMenuOpenChat;

  /// No description provided for @contextMenuPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get contextMenuPin;

  /// No description provided for @contextMenuUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get contextMenuUnpin;

  /// No description provided for @mediaViewerAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to see this twonly!'**
  String get mediaViewerAuthReason;

  /// No description provided for @mediaViewerTwonlyTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open your twonly!'**
  String get mediaViewerTwonlyTapToOpen;

  /// No description provided for @messageSendState_Received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get messageSendState_Received;

  /// No description provided for @messageSendState_Opened.
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get messageSendState_Opened;

  /// No description provided for @messageSendState_Send.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get messageSendState_Send;

  /// No description provided for @messageSendState_Sending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get messageSendState_Sending;

  /// No description provided for @messageSendState_TapToLoad.
  ///
  /// In en, this message translates to:
  /// **'Tap to load'**
  String get messageSendState_TapToLoad;

  /// No description provided for @messageSendState_Loading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get messageSendState_Loading;

  /// No description provided for @messageStoredInGallery.
  ///
  /// In en, this message translates to:
  /// **'Stored in gallery'**
  String get messageStoredInGallery;

  /// No description provided for @messageReopened.
  ///
  /// In en, this message translates to:
  /// **'Re-opened'**
  String get messageReopened;

  /// No description provided for @imageEditorDrawOk.
  ///
  /// In en, this message translates to:
  /// **'Take drawing'**
  String get imageEditorDrawOk;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get settingsChats;

  /// No description provided for @settingsPreSelectedReactions.
  ///
  /// In en, this message translates to:
  /// **'Preselected reaction emojis'**
  String get settingsPreSelectedReactions;

  /// No description provided for @settingsPreSelectedReactionsError.
  ///
  /// In en, this message translates to:
  /// **'A maximum of 12 reactions can be selected.'**
  String get settingsPreSelectedReactionsError;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsStorageData.
  ///
  /// In en, this message translates to:
  /// **'Data and storage'**
  String get settingsStorageData;

  /// No description provided for @settingsStorageDataStoreInGTitle.
  ///
  /// In en, this message translates to:
  /// **'Store in Gallery'**
  String get settingsStorageDataStoreInGTitle;

  /// No description provided for @settingsStorageDataStoreInGSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Store saved images additional in the systems gallery.'**
  String get settingsStorageDataStoreInGSubtitle;

  /// No description provided for @settingsStorageDataMediaAutoDownload.
  ///
  /// In en, this message translates to:
  /// **'Media auto-download'**
  String get settingsStorageDataMediaAutoDownload;

  /// No description provided for @settingsStorageDataAutoDownMobile.
  ///
  /// In en, this message translates to:
  /// **'When using mobile data'**
  String get settingsStorageDataAutoDownMobile;

  /// No description provided for @settingsStorageDataAutoDownWifi.
  ///
  /// In en, this message translates to:
  /// **'When using WI-FI'**
  String get settingsStorageDataAutoDownWifi;

  /// No description provided for @settingsProfileCustomizeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Customize your avatar'**
  String get settingsProfileCustomizeAvatar;

  /// No description provided for @settingsProfileEditDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Displayname'**
  String get settingsProfileEditDisplayName;

  /// No description provided for @settingsProfileEditDisplayNameNew.
  ///
  /// In en, this message translates to:
  /// **'New Displayname'**
  String get settingsProfileEditDisplayNameNew;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Konto'**
  String get settingsAccount;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBlockUsers.
  ///
  /// In en, this message translates to:
  /// **'Block users'**
  String get settingsPrivacyBlockUsers;

  /// No description provided for @settingsPrivacyBlockUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Blocked users will not be able to communicate with you. You can unblock a blocked user at any time.'**
  String get settingsPrivacyBlockUsersDesc;

  /// No description provided for @settingsPrivacyBlockUsersCount.
  ///
  /// In en, this message translates to:
  /// **'{len} contact(s)'**
  String settingsPrivacyBlockUsersCount(Object len);

  /// No description provided for @settingsNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get settingsNotification;

  /// No description provided for @settingsNotifyTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get settingsNotifyTroubleshooting;

  /// No description provided for @settingsNotifyTroubleshootingDesc.
  ///
  /// In en, this message translates to:
  /// **'Click here if you have problems receiving push notifications.'**
  String get settingsNotifyTroubleshootingDesc;

  /// No description provided for @settingsNotifyTroubleshootingNoProblem.
  ///
  /// In en, this message translates to:
  /// **'No problem detected'**
  String get settingsNotifyTroubleshootingNoProblem;

  /// No description provided for @settingsNotifyTroubleshootingNoProblemDesc.
  ///
  /// In en, this message translates to:
  /// **'Press OK to receive a test notification. When you receive no message even after waiting for 10 minutes, please send us your debug log in Settings > Help > Debug log, so we can look at that issue.'**
  String get settingsNotifyTroubleshootingNoProblemDesc;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settingsHelp;

  /// No description provided for @settingsHelpDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic protocol'**
  String get settingsHelpDiagnostics;

  /// No description provided for @settingsHelpFAQ.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get settingsHelpFAQ;

  /// No description provided for @feedbackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Give Feedback to improve twonly.'**
  String get feedbackTooltip;

  /// No description provided for @settingsHelpContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get settingsHelpContactUs;

  /// No description provided for @settingsHelpVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsHelpVersion;

  /// No description provided for @settingsHelpLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses (Source-Code)'**
  String get settingsHelpLicenses;

  /// No description provided for @settingsHelpCredits.
  ///
  /// In en, this message translates to:
  /// **'Licenses (Images)'**
  String get settingsHelpCredits;

  /// No description provided for @settingsHelpImprint.
  ///
  /// In en, this message translates to:
  /// **'Imprint & Privacy Policy'**
  String get settingsHelpImprint;

  /// No description provided for @contactUsFaq.
  ///
  /// In en, this message translates to:
  /// **'Have you read our FAQ yet?'**
  String get contactUsFaq;

  /// No description provided for @contactUsEmojis.
  ///
  /// In en, this message translates to:
  /// **'How do you feel? (optional)'**
  String get contactUsEmojis;

  /// No description provided for @contactUsSelectOption.
  ///
  /// In en, this message translates to:
  /// **'Please select an option'**
  String get contactUsSelectOption;

  /// No description provided for @contactUsReason.
  ///
  /// In en, this message translates to:
  /// **'Tell us why you\'re reaching out'**
  String get contactUsReason;

  /// No description provided for @contactUsMessage.
  ///
  /// In en, this message translates to:
  /// **'If you want to receive an answer, please add your e-mail address so we can contact you.'**
  String get contactUsMessage;

  /// No description provided for @contactUsYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get contactUsYourMessage;

  /// No description provided for @contactUsMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what\'s going on'**
  String get contactUsMessageTitle;

  /// No description provided for @contactUsReasonNotWorking.
  ///
  /// In en, this message translates to:
  /// **'Something\'s not working'**
  String get contactUsReasonNotWorking;

  /// No description provided for @contactUsReasonFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature request'**
  String get contactUsReasonFeatureRequest;

  /// No description provided for @contactUsReasonQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get contactUsReasonQuestion;

  /// No description provided for @contactUsReasonFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get contactUsReasonFeedback;

  /// No description provided for @contactUsReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get contactUsReasonOther;

  /// No description provided for @contactUsIncludeLog.
  ///
  /// In en, this message translates to:
  /// **'Include debug log'**
  String get contactUsIncludeLog;

  /// No description provided for @contactUsWhatsThat.
  ///
  /// In en, this message translates to:
  /// **'What\'s that?'**
  String get contactUsWhatsThat;

  /// No description provided for @contactUsLastWarning.
  ///
  /// In en, this message translates to:
  /// **'This are the information\'s which will be send to us. Please verify them and then press submit.'**
  String get contactUsLastWarning;

  /// No description provided for @contactUsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted successfully!'**
  String get contactUsSuccess;

  /// No description provided for @contactUsShortcut.
  ///
  /// In en, this message translates to:
  /// **'Hide Feedback Icon'**
  String get contactUsShortcut;

  /// No description provided for @settingsHelpTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsHelpTerms;

  /// No description provided for @settingsAppearanceTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsAppearanceTheme;

  /// No description provided for @settingsAccountDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsAccountDeleteAccount;

  /// No description provided for @settingsAccountDeleteAccountWithBallance.
  ///
  /// In en, this message translates to:
  /// **'In the next step, you can select what you want to to with the remaining credit ({credit}).'**
  String settingsAccountDeleteAccountWithBallance(Object credit);

  /// No description provided for @settingsAccountDeleteAccountNoBallance.
  ///
  /// In en, this message translates to:
  /// **'Once you delete your account, there is no going back.'**
  String get settingsAccountDeleteAccountNoBallance;

  /// No description provided for @settingsAccountDeleteAccountNoInternet.
  ///
  /// In en, this message translates to:
  /// **'An Internet connection is required to delete your account.'**
  String get settingsAccountDeleteAccountNoInternet;

  /// No description provided for @settingsAccountDeleteModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get settingsAccountDeleteModalTitle;

  /// No description provided for @settingsAccountDeleteModalBody.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deleted. There is no change to restore it.'**
  String get settingsAccountDeleteModalBody;

  /// No description provided for @contactVerifyNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify safety number'**
  String get contactVerifyNumberTitle;

  /// No description provided for @contactVerifyNumberTapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap to scan'**
  String get contactVerifyNumberTapToScan;

  /// No description provided for @contactVerifyNumberMarkAsVerified.
  ///
  /// In en, this message translates to:
  /// **'Mark as verified'**
  String get contactVerifyNumberMarkAsVerified;

  /// No description provided for @contactVerifyNumberClearVerification.
  ///
  /// In en, this message translates to:
  /// **'Clear verification'**
  String get contactVerifyNumberClearVerification;

  /// No description provided for @contactVerifyNumberLongDesc.
  ///
  /// In en, this message translates to:
  /// **'To verify the end-to-end encryption with {username}, compare the numbers with their device. The person can also scan your code with their device.'**
  String contactVerifyNumberLongDesc(Object username);

  /// No description provided for @contactNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get contactNickname;

  /// No description provided for @contactNicknameNew.
  ///
  /// In en, this message translates to:
  /// **'New nickname'**
  String get contactNicknameNew;

  /// No description provided for @deleteAllContactMessages.
  ///
  /// In en, this message translates to:
  /// **'Delete all text-messages'**
  String get deleteAllContactMessages;

  /// No description provided for @deleteAllContactMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all messages, except stored media files, in your chat with {username}. This will NOT delete the messages stored at {username}s device!'**
  String deleteAllContactMessagesBody(Object username);

  /// No description provided for @contactBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get contactBlock;

  /// No description provided for @contactBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {username}'**
  String contactBlockTitle(Object username);

  /// No description provided for @contactBlockBody.
  ///
  /// In en, this message translates to:
  /// **'A blocked user will no longer be able to send you messages and their profile will be hidden from view. To unblock a user, simply navigate to Settings > Privacy > Blocked Users.'**
  String get contactBlockBody;

  /// No description provided for @contactRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove user'**
  String get contactRemove;

  /// No description provided for @contactRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {username}'**
  String contactRemoveTitle(Object username);

  /// No description provided for @contactRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Remove the user and permanently delete the chat and all associated media files. This will also delete YOUR ACCOUNT FROM YOUR CONTACT\'S PHONE.'**
  String get contactRemoveBody;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min.'**
  String get minutesShort;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @react.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get react;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @switchFrontAndBackCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch between front and back camera.'**
  String get switchFrontAndBackCamera;

  /// No description provided for @addTextItem.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get addTextItem;

  /// No description provided for @protectAsARealTwonly.
  ///
  /// In en, this message translates to:
  /// **'Send as real twonly!'**
  String get protectAsARealTwonly;

  /// No description provided for @addDrawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get addDrawing;

  /// No description provided for @addEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get addEmoji;

  /// No description provided for @toggleFlashLight.
  ///
  /// In en, this message translates to:
  /// **'Toggle the flash light'**
  String get toggleFlashLight;

  /// No description provided for @toggleHighQuality.
  ///
  /// In en, this message translates to:
  /// **'Toggle better resolution'**
  String get toggleHighQuality;

  /// No description provided for @userFound.
  ///
  /// In en, this message translates to:
  /// **'User found'**
  String get userFound;

  /// No description provided for @userFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to create a follow request?'**
  String get userFoundBody;

  /// No description provided for @searchUsernameNotFoundLong.
  ///
  /// In en, this message translates to:
  /// **'\"{username}\" is not a twonly user. Please check the username and try again.'**
  String searchUsernameNotFoundLong(Object username);

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error has occurred. Please try again later.'**
  String get errorUnknown;

  /// No description provided for @errorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'The request could not be understood by the server due to malformed syntax. Please check your input and try again.'**
  String get errorBadRequest;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'You have made too many requests in a short period. Please wait a moment before trying again.'**
  String get errorTooManyRequests;

  /// No description provided for @errorInternalError.
  ///
  /// In en, this message translates to:
  /// **'The server is currently not available. Please try again later.'**
  String get errorInternalError;

  /// No description provided for @errorInvalidInvitationCode.
  ///
  /// In en, this message translates to:
  /// **'The invitation code you provided is invalid. Please check the code and try again.'**
  String get errorInvalidInvitationCode;

  /// No description provided for @errorUsernameAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'The username is already taken.'**
  String get errorUsernameAlreadyTaken;

  /// No description provided for @errorSignatureNotValid.
  ///
  /// In en, this message translates to:
  /// **'The provided signature is not valid. Please check your credentials and try again.'**
  String get errorSignatureNotValid;

  /// No description provided for @errorUsernameNotFound.
  ///
  /// In en, this message translates to:
  /// **'The username you entered does not exist. Please check the spelling or create a new account.'**
  String get errorUsernameNotFound;

  /// No description provided for @errorUsernameNotValid.
  ///
  /// In en, this message translates to:
  /// **'The username you provided does not meet the required criteria. Please choose a valid username.'**
  String get errorUsernameNotValid;

  /// No description provided for @errorInvalidPublicKey.
  ///
  /// In en, this message translates to:
  /// **'The public key you provided is invalid. Please check the key and try again.'**
  String get errorInvalidPublicKey;

  /// No description provided for @errorSessionAlreadyAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'You are already logged in. Please log out if you want to log in with a different account.'**
  String get errorSessionAlreadyAuthenticated;

  /// No description provided for @errorSessionNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Your session is not authenticated. Please log in to continue.'**
  String get errorSessionNotAuthenticated;

  /// No description provided for @errorOnlyOneSessionAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only one active session is allowed per user. Please log out from other devices to continue.'**
  String get errorOnlyOneSessionAllowed;

  /// No description provided for @errorNotEnoughCredit.
  ///
  /// In en, this message translates to:
  /// **'You do not have enough twonly-credit.'**
  String get errorNotEnoughCredit;

  /// No description provided for @errorVoucherInvalid.
  ///
  /// In en, this message translates to:
  /// **'The voucher code you entered is not valid.'**
  String get errorVoucherInvalid;

  /// No description provided for @errorPlanLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached your plans limit. Please upgrade your plan.'**
  String get errorPlanLimitReached;

  /// No description provided for @errorPlanNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This feature is not available in your current plan.'**
  String get errorPlanNotAllowed;

  /// No description provided for @errorPlanUpgradeNotYearly.
  ///
  /// In en, this message translates to:
  /// **'The plan upgrade must be paid for annually, as the current plan is also billed annually.'**
  String get errorPlanUpgradeNotYearly;

  /// No description provided for @upgradeToPaidPlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to a paid plan.'**
  String get upgradeToPaidPlan;

  /// No description provided for @upgradeToPaidPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade subscription to {planId}'**
  String upgradeToPaidPlanButton(Object planId);

  /// No description provided for @partOfPaidPlanOf.
  ///
  /// In en, this message translates to:
  /// **'You are part of the paid plan of {username}!'**
  String partOfPaidPlanOf(Object username);

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @proFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ Unlimited media file uploads'**
  String get proFeature1;

  /// No description provided for @proFeature2.
  ///
  /// In en, this message translates to:
  /// **'1 additional Plus user'**
  String get proFeature2;

  /// No description provided for @proFeature3.
  ///
  /// In en, this message translates to:
  /// **'Cloud-Backup encrypted (coming-soon)'**
  String get proFeature3;

  /// No description provided for @proFeature4.
  ///
  /// In en, this message translates to:
  /// **'Additional features (coming-soon)'**
  String get proFeature4;

  /// No description provided for @familyFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ All from Pro'**
  String get familyFeature1;

  /// No description provided for @familyFeature2.
  ///
  /// In en, this message translates to:
  /// **'4 additional Plus users'**
  String get familyFeature2;

  /// No description provided for @redeemUserInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Or redeem a twonly-Code.'**
  String get redeemUserInviteCode;

  /// No description provided for @redeemUserInviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem twonly-Code'**
  String get redeemUserInviteCodeTitle;

  /// No description provided for @redeemUserInviteCodeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your plan has been successfully adjusted.'**
  String get redeemUserInviteCodeSuccess;

  /// No description provided for @freeFeature1.
  ///
  /// In en, this message translates to:
  /// **'10 Media file uploads per day'**
  String get freeFeature1;

  /// No description provided for @plusFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ Unlimited media file uploads'**
  String get plusFeature1;

  /// No description provided for @plusFeature2.
  ///
  /// In en, this message translates to:
  /// **'Additional features (coming-soon)'**
  String get plusFeature2;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Your transaction history'**
  String get transactionHistory;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscription'**
  String get manageSubscription;

  /// No description provided for @nextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next payment'**
  String get nextPayment;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @manageAdditionalUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage additional users'**
  String get manageAdditionalUsers;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @createOrRedeemVoucher.
  ///
  /// In en, this message translates to:
  /// **'Buy or redeem voucher'**
  String get createOrRedeemVoucher;

  /// No description provided for @createVoucher.
  ///
  /// In en, this message translates to:
  /// **'Buy voucher'**
  String get createVoucher;

  /// No description provided for @createVoucherDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the value of the voucher. The value of the voucher will be deducted from your twonly balance.'**
  String get createVoucherDesc;

  /// No description provided for @redeemVoucher.
  ///
  /// In en, this message translates to:
  /// **'Redeem voucher'**
  String get redeemVoucher;

  /// No description provided for @openVouchers.
  ///
  /// In en, this message translates to:
  /// **'Open vouchers'**
  String get openVouchers;

  /// No description provided for @voucherCreated.
  ///
  /// In en, this message translates to:
  /// **'Voucher created'**
  String get voucherCreated;

  /// No description provided for @voucherRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Voucher redeemed'**
  String get voucherRedeemed;

  /// No description provided for @enterVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Voucher Code'**
  String get enterVoucherCode;

  /// No description provided for @requestedVouchers.
  ///
  /// In en, this message translates to:
  /// **'Requested vouchers'**
  String get requestedVouchers;

  /// No description provided for @redeemedVouchers.
  ///
  /// In en, this message translates to:
  /// **'Redeemed vouchers'**
  String get redeemedVouchers;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @subscriptionRefund.
  ///
  /// In en, this message translates to:
  /// **'When you upgrade, you will receive a refund of {refund} for your current subscription.'**
  String subscriptionRefund(Object refund);

  /// No description provided for @transactionCash.
  ///
  /// In en, this message translates to:
  /// **'Cash transaction'**
  String get transactionCash;

  /// No description provided for @transactionPlanUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Plan upgrade'**
  String get transactionPlanUpgrade;

  /// No description provided for @transactionRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund transaction'**
  String get transactionRefund;

  /// No description provided for @transactionThanksForTesting.
  ///
  /// In en, this message translates to:
  /// **'Thank you for testing'**
  String get transactionThanksForTesting;

  /// No description provided for @transactionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown transaction'**
  String get transactionUnknown;

  /// No description provided for @transactionVoucherCreated.
  ///
  /// In en, this message translates to:
  /// **'Voucher created'**
  String get transactionVoucherCreated;

  /// No description provided for @transactionVoucherRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Voucher redeemed'**
  String get transactionVoucherRedeemed;

  /// No description provided for @transactionAutoRenewal.
  ///
  /// In en, this message translates to:
  /// **'Automatic renewal'**
  String get transactionAutoRenewal;

  /// No description provided for @checkoutOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get checkoutOptions;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @checkoutPayYearly.
  ///
  /// In en, this message translates to:
  /// **'Pay yearly'**
  String get checkoutPayYearly;

  /// No description provided for @checkoutTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get checkoutTotal;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @twonlyCredit.
  ///
  /// In en, this message translates to:
  /// **'twonly-Credit'**
  String get twonlyCredit;

  /// No description provided for @notEnoughCredit.
  ///
  /// In en, this message translates to:
  /// **'You do not have enough credit!'**
  String get notEnoughCredit;

  /// No description provided for @chargeCredit.
  ///
  /// In en, this message translates to:
  /// **'Charge credit'**
  String get chargeCredit;

  /// No description provided for @autoRenewal.
  ///
  /// In en, this message translates to:
  /// **'Auto renewal'**
  String get autoRenewal;

  /// No description provided for @autoRenewalDesc.
  ///
  /// In en, this message translates to:
  /// **'You can change this at any time.'**
  String get autoRenewalDesc;

  /// No description provided for @autoRenewalLongDesc.
  ///
  /// In en, this message translates to:
  /// **'When your subscription expires, you will automatically be downgraded to the Preview plan. If you activate the automatic renewal, please make sure that you have enough credit for the automatic renewal.  We will notify you in good time before the automatic renewal.'**
  String get autoRenewalLongDesc;

  /// No description provided for @planSuccessUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Successfully upgraded your plan.'**
  String get planSuccessUpgraded;

  /// No description provided for @checkoutSubmit.
  ///
  /// In en, this message translates to:
  /// **'Order with a fee.'**
  String get checkoutSubmit;

  /// No description provided for @additionalUsersList.
  ///
  /// In en, this message translates to:
  /// **'Your additional users'**
  String get additionalUsersList;

  /// No description provided for @additionalUsersPlusTokens.
  ///
  /// In en, this message translates to:
  /// **'twonly-Codes für \"Plus\" user'**
  String get additionalUsersPlusTokens;

  /// No description provided for @additionalUsersFreeTokens.
  ///
  /// In en, this message translates to:
  /// **'twonly-Codes für \"Free\" user'**
  String get additionalUsersFreeTokens;

  /// No description provided for @planLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached your plan limit for today. Upgrade your plan now to send the media file.'**
  String get planLimitReached;

  /// No description provided for @planNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You cannot send media files with your current tariff.  Upgrade your plan now to send the media file.'**
  String get planNotAllowed;

  /// No description provided for @galleryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get galleryDelete;

  /// No description provided for @galleryDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get galleryDetails;

  /// No description provided for @galleryExport.
  ///
  /// In en, this message translates to:
  /// **'Export to gallery'**
  String get galleryExport;

  /// No description provided for @galleryExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully saved in the Gallery.'**
  String get galleryExportSuccess;

  /// No description provided for @settingsResetTutorials.
  ///
  /// In en, this message translates to:
  /// **'Show tutorials again'**
  String get settingsResetTutorials;

  /// No description provided for @settingsResetTutorialsDesc.
  ///
  /// In en, this message translates to:
  /// **'Click here to show already displayed tutorials again.'**
  String get settingsResetTutorialsDesc;

  /// No description provided for @settingsResetTutorialsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tutorials will be displayed again.'**
  String get settingsResetTutorialsSuccess;

  /// No description provided for @tutorialChatListSearchUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Friends and Manage Friend Requests'**
  String get tutorialChatListSearchUsersTitle;

  /// No description provided for @tutorialChatListSearchUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'If you know your friends\' usernames, you can search for them here and send a friend request. You will also see all requests from other users that you can accept or block.'**
  String get tutorialChatListSearchUsersDesc;

  /// No description provided for @tutorialChatListContextMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Long press on the contact to open the context menu.'**
  String get tutorialChatListContextMenuTitle;

  /// No description provided for @tutorialChatListContextMenuDesc.
  ///
  /// In en, this message translates to:
  /// **'With the context menu, you can pin, archive, and perform various actions on your contacts. Simply long press the contact and then move your finger to the desired option or tap directly on it.'**
  String get tutorialChatListContextMenuDesc;

  /// No description provided for @tutorialChatMessagesVerifyShieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your contacts!'**
  String get tutorialChatMessagesVerifyShieldTitle;

  /// No description provided for @tutorialChatMessagesVerifyShieldDesc.
  ///
  /// In en, this message translates to:
  /// **'twonly uses the Signal protocol for secure end-to-end encryption. When you first contact someone, their public identity key is downloaded. To ensure that this key has not been tampered with by third parties, you should compare it with your friend when you meet in person. Once you have verified the user, you can also enable the twonly mode when sending images and videos.'**
  String get tutorialChatMessagesVerifyShieldDesc;

  /// No description provided for @tutorialChatMessagesReopenMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen Images and Videos'**
  String get tutorialChatMessagesReopenMessageTitle;

  /// No description provided for @tutorialChatMessagesReopenMessageDesc.
  ///
  /// In en, this message translates to:
  /// **'If your friend has sent you a picture or video with infinite display time, you can open it again at any time until you restart the app. To do this, simply double-click on the message. Your friend will then receive a notification that you have viewed the picture again.'**
  String get tutorialChatMessagesReopenMessageDesc;

  /// No description provided for @memoriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'As soon as you save pictures or videos, they end up here in your memories.'**
  String get memoriesEmpty;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteTitle;

  /// No description provided for @deleteOkBtnForAll.
  ///
  /// In en, this message translates to:
  /// **'Delete for all'**
  String get deleteOkBtnForAll;

  /// No description provided for @deleteOkBtnForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get deleteOkBtnForMe;

  /// No description provided for @deleteImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteImageTitle;

  /// No description provided for @deleteImageBody.
  ///
  /// In en, this message translates to:
  /// **'The image will be irrevocably deleted.'**
  String get deleteImageBody;

  /// No description provided for @settingsBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsBackup;

  /// No description provided for @backupNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'No backup configured'**
  String get backupNoticeTitle;

  /// No description provided for @backupNoticeDesc.
  ///
  /// In en, this message translates to:
  /// **'If you change or lose your device, no one can restore your account without a backup. Therefore, back up your data.'**
  String get backupNoticeDesc;

  /// No description provided for @backupNoticeLater.
  ///
  /// In en, this message translates to:
  /// **'Remind later'**
  String get backupNoticeLater;

  /// No description provided for @backupNoticeOpenBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backupNoticeOpenBackup;

  /// No description provided for @backupPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get backupPending;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get backupFailed;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get backupSuccess;

  /// No description provided for @backupTwonlySafeDesc.
  ///
  /// In en, this message translates to:
  /// **'Back up your twonly identity, as this is the only way to restore your account if you uninstall the app or lose your phone.'**
  String get backupTwonlySafeDesc;

  /// No description provided for @backupNoPasswordRecovery.
  ///
  /// In en, this message translates to:
  /// **'Due to twonly\'s security system, there is (currently) no password recovery function. Therefore, you must remember your password or, better yet, write it down.'**
  String get backupNoPasswordRecovery;

  /// No description provided for @backupServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get backupServer;

  /// No description provided for @backupMaxBackupSize.
  ///
  /// In en, this message translates to:
  /// **'max. backup size'**
  String get backupMaxBackupSize;

  /// No description provided for @backupStorageRetention.
  ///
  /// In en, this message translates to:
  /// **'Storage retention'**
  String get backupStorageRetention;

  /// No description provided for @backupLastBackupDate.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get backupLastBackupDate;

  /// No description provided for @backupLastBackupSize.
  ///
  /// In en, this message translates to:
  /// **'Backup size'**
  String get backupLastBackupSize;

  /// No description provided for @backupLastBackupResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get backupLastBackupResult;

  /// No description provided for @deleteBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteBackupTitle;

  /// No description provided for @deleteBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Without an backup, you can not restore your user account.'**
  String get deleteBackupBody;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Data-Backup'**
  String get backupData;

  /// No description provided for @backupDataDesc.
  ///
  /// In en, this message translates to:
  /// **'This backup contains besides of your twonly-Identity also all of your media files. This backup will is also encrypted but stored locally. You then have to ensure to manually copy it onto your laptop or device of your choice.'**
  String get backupDataDesc;

  /// No description provided for @backupInsecurePassword.
  ///
  /// In en, this message translates to:
  /// **'Insecure password'**
  String get backupInsecurePassword;

  /// No description provided for @backupInsecurePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'The chosen password is very insecure and can therefore easily be guessed by attackers. Please choose a secure password.'**
  String get backupInsecurePasswordDesc;

  /// No description provided for @backupInsecurePasswordOk.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get backupInsecurePasswordOk;

  /// No description provided for @backupInsecurePasswordCancel.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get backupInsecurePasswordCancel;

  /// No description provided for @backupTwonlySafeLongDesc.
  ///
  /// In en, this message translates to:
  /// **'twonly does not have any central user accounts. A key pair is created during installation, which consists of a public and a private key. The private key is only stored on your device to protect it from unauthorized access. The public key is uploaded to the server and linked to your chosen username so that others can find you.\n\ntwonly Backup regularly creates an encrypted, anonymous backup of your private key together with your contacts and settings. Your username and chosen password are enough to restore this data on another device.'**
  String get backupTwonlySafeLongDesc;

  /// No description provided for @backupSelectStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a secure password. This is required if you want to restore your twonly Backup.'**
  String get backupSelectStrongPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRepeated.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get passwordRepeated;

  /// No description provided for @passwordRepeatedNotEqual.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordRepeatedNotEqual;

  /// No description provided for @backupPasswordRequirement.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long.'**
  String get backupPasswordRequirement;

  /// No description provided for @backupExpertSettings.
  ///
  /// In en, this message translates to:
  /// **'Expert settings'**
  String get backupExpertSettings;

  /// No description provided for @backupEnableBackup.
  ///
  /// In en, this message translates to:
  /// **'Activate automatic backup'**
  String get backupEnableBackup;

  /// No description provided for @backupOwnServerDesc.
  ///
  /// In en, this message translates to:
  /// **'Save your twonly Backup at twonly or on any server of your choice.'**
  String get backupOwnServerDesc;

  /// No description provided for @backupUseOwnServer.
  ///
  /// In en, this message translates to:
  /// **'Use server'**
  String get backupUseOwnServer;

  /// No description provided for @backupResetServer.
  ///
  /// In en, this message translates to:
  /// **'Use standard server'**
  String get backupResetServer;

  /// No description provided for @backupTwonlySaveNow.
  ///
  /// In en, this message translates to:
  /// **'Save now'**
  String get backupTwonlySaveNow;

  /// No description provided for @backupChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get backupChangePassword;

  /// No description provided for @twonlySafeRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get twonlySafeRecoverTitle;

  /// No description provided for @twonlySafeRecoverDesc.
  ///
  /// In en, this message translates to:
  /// **'If you have created a backup with twonly Backup, you can restore it here.'**
  String get twonlySafeRecoverDesc;

  /// No description provided for @twonlySafeRecoverBtn.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get twonlySafeRecoverBtn;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite your friends'**
  String get inviteFriends;

  /// No description provided for @inviteFriendsShareBtn.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get inviteFriendsShareBtn;

  /// No description provided for @inviteFriendsShareText.
  ///
  /// In en, this message translates to:
  /// **'Let\'s switch to twonly: {url}'**
  String inviteFriendsShareText(Object url);

  /// No description provided for @appOutdated.
  ///
  /// In en, this message translates to:
  /// **'Your version of twonly is out of date.'**
  String get appOutdated;

  /// No description provided for @appOutdatedBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get appOutdatedBtn;

  /// No description provided for @doubleClickToReopen.
  ///
  /// In en, this message translates to:
  /// **'Double-click\nto open again'**
  String get doubleClickToReopen;

  /// No description provided for @uploadLimitReached.
  ///
  /// In en, this message translates to:
  /// **'The upload limit has\been reached. Upgrade to Pro\nor wait until tomorrow.'**
  String get uploadLimitReached;

  /// No description provided for @retransmissionRequested.
  ///
  /// In en, this message translates to:
  /// **'Retransmission requested'**
  String get retransmissionRequested;

  /// No description provided for @testPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the interest in a paid plan. Currently the paid plans are still deactivated. But they will be activated soon!'**
  String get testPaymentMethod;

  /// No description provided for @openChangeLog.
  ///
  /// In en, this message translates to:
  /// **'Open changelog automatically'**
  String get openChangeLog;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {username}'**
  String reportUserTitle(Object username);

  /// No description provided for @reportUserReason.
  ///
  /// In en, this message translates to:
  /// **'Reporting reason'**
  String get reportUserReason;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @newDeviceRegistered.
  ///
  /// In en, this message translates to:
  /// **'You have logged in on another device. You have therefore been logged out here.'**
  String get newDeviceRegistered;

  /// No description provided for @tabToRemoveEmoji.
  ///
  /// In en, this message translates to:
  /// **'Tab to remove'**
  String get tabToRemoveEmoji;

  /// No description provided for @quotedMessageWasDeleted.
  ///
  /// In en, this message translates to:
  /// **'The quoted message has been deleted.'**
  String get quotedMessageWasDeleted;

  /// No description provided for @messageWasDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message has been deleted.'**
  String get messageWasDeleted;

  /// No description provided for @messageWasDeletedShort.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get messageWasDeletedShort;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get sent;

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Delivered to'**
  String get sentTo;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @opened.
  ///
  /// In en, this message translates to:
  /// **'Opened'**
  String get opened;

  /// No description provided for @waitingForInternet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for internet'**
  String get waitingForInternet;

  /// No description provided for @editHistory.
  ///
  /// In en, this message translates to:
  /// **'Edit history'**
  String get editHistory;

  /// No description provided for @archivedChats.
  ///
  /// In en, this message translates to:
  /// **'Archived chats'**
  String get archivedChats;

  /// No description provided for @durationShortSecond.
  ///
  /// In en, this message translates to:
  /// **'Sec.'**
  String get durationShortSecond;

  /// No description provided for @durationShortMinute.
  ///
  /// In en, this message translates to:
  /// **'Min.'**
  String get durationShortMinute;

  /// No description provided for @durationShortHour.
  ///
  /// In en, this message translates to:
  /// **'Hrs.'**
  String get durationShortHour;

  /// No description provided for @durationShortDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Day} other{{count} Days}}'**
  String durationShortDays(num count);

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @selectMembers.
  ///
  /// In en, this message translates to:
  /// **'Select members'**
  String get selectMembers;

  /// No description provided for @selectGroupName.
  ///
  /// In en, this message translates to:
  /// **'Select group name'**
  String get selectGroupName;

  /// No description provided for @groupNameInput.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameInput;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembers;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @createContactRequest.
  ///
  /// In en, this message translates to:
  /// **'Create contact request'**
  String get createContactRequest;

  /// No description provided for @contactRequestSend.
  ///
  /// In en, this message translates to:
  /// **'Contact request send'**
  String get contactRequestSend;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove as admin'**
  String get removeAdmin;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @revokeAdminRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke {username}\'s admin rights?'**
  String revokeAdminRightsTitle(Object username);

  /// No description provided for @revokeAdminRightsOkBtn.
  ///
  /// In en, this message translates to:
  /// **'Remove as admin'**
  String get revokeAdminRightsOkBtn;

  /// No description provided for @makeAdminRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Make {username} an admin?'**
  String makeAdminRightsTitle(Object username);

  /// No description provided for @makeAdminRightsBody.
  ///
  /// In en, this message translates to:
  /// **'{username} will be able to edit this group and its members.'**
  String makeAdminRightsBody(Object username);

  /// No description provided for @makeAdminRightsOkBtn.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdminRightsOkBtn;

  /// No description provided for @updateGroup.
  ///
  /// In en, this message translates to:
  /// **'Update group'**
  String get updateGroup;

  /// No description provided for @alreadyInGroup.
  ///
  /// In en, this message translates to:
  /// **'Already in Group'**
  String get alreadyInGroup;

  /// No description provided for @removeContactFromGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {username} from this group?'**
  String removeContactFromGroupTitle(Object username);

  /// No description provided for @youChangedGroupName.
  ///
  /// In en, this message translates to:
  /// **'You have changed the group name to \"{newGroupName}\".'**
  String youChangedGroupName(Object newGroupName);

  /// No description provided for @makerChangedGroupName.
  ///
  /// In en, this message translates to:
  /// **'{maker} has changed the group name to \"{newGroupName}\".'**
  String makerChangedGroupName(Object maker, Object newGroupName);

  /// No description provided for @youCreatedGroup.
  ///
  /// In en, this message translates to:
  /// **'You have created the group.'**
  String get youCreatedGroup;

  /// No description provided for @makerCreatedGroup.
  ///
  /// In en, this message translates to:
  /// **'{maker} has created the group.'**
  String makerCreatedGroup(Object maker);

  /// No description provided for @youRemovedMember.
  ///
  /// In en, this message translates to:
  /// **'You have removed {affected} from the group.'**
  String youRemovedMember(Object affected);

  /// No description provided for @makerRemovedMember.
  ///
  /// In en, this message translates to:
  /// **'{maker} has removed {affected} from the group.'**
  String makerRemovedMember(Object affected, Object maker);

  /// No description provided for @youAddedMember.
  ///
  /// In en, this message translates to:
  /// **'You have added {affected} to the group.'**
  String youAddedMember(Object affected);

  /// No description provided for @makerAddedMember.
  ///
  /// In en, this message translates to:
  /// **'{maker} has added {affected} to the group.'**
  String makerAddedMember(Object affected, Object maker);

  /// No description provided for @youMadeAdmin.
  ///
  /// In en, this message translates to:
  /// **'You made {affected} an admin.'**
  String youMadeAdmin(Object affected);

  /// No description provided for @makerMadeAdmin.
  ///
  /// In en, this message translates to:
  /// **'{maker} made {affected} an admin.'**
  String makerMadeAdmin(Object affected, Object maker);

  /// No description provided for @youRevokedAdminRights.
  ///
  /// In en, this message translates to:
  /// **'You revoked {affectedR} admin rights.'**
  String youRevokedAdminRights(Object affectedR);

  /// No description provided for @makerRevokedAdminRights.
  ///
  /// In en, this message translates to:
  /// **'{maker} revoked {affectedR} admin rights.'**
  String makerRevokedAdminRights(Object affectedR, Object maker);

  /// No description provided for @youLeftGroup.
  ///
  /// In en, this message translates to:
  /// **'You have left the group.'**
  String get youLeftGroup;

  /// No description provided for @makerLeftGroup.
  ///
  /// In en, this message translates to:
  /// **'{maker} has left the group.'**
  String makerLeftGroup(Object maker);

  /// No description provided for @groupActionYou.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get groupActionYou;

  /// No description provided for @groupActionYour.
  ///
  /// In en, this message translates to:
  /// **'your'**
  String get groupActionYour;

  /// No description provided for @notificationFillerIn.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get notificationFillerIn;

  /// No description provided for @notificationText.
  ///
  /// In en, this message translates to:
  /// **'sent a message{inGroup}.'**
  String notificationText(Object inGroup);

  /// No description provided for @notificationTwonly.
  ///
  /// In en, this message translates to:
  /// **'sent a twonly{inGroup}.'**
  String notificationTwonly(Object inGroup);

  /// No description provided for @notificationVideo.
  ///
  /// In en, this message translates to:
  /// **'sent a video{inGroup}.'**
  String notificationVideo(Object inGroup);

  /// No description provided for @notificationImage.
  ///
  /// In en, this message translates to:
  /// **'sent a image{inGroup}.'**
  String notificationImage(Object inGroup);

  /// No description provided for @notificationAudio.
  ///
  /// In en, this message translates to:
  /// **'sent a voice message{inGroup}.'**
  String notificationAudio(Object inGroup);

  /// No description provided for @notificationAddedToGroup.
  ///
  /// In en, this message translates to:
  /// **'has added you to \"{groupname}\"'**
  String notificationAddedToGroup(Object groupname);

  /// No description provided for @notificationContactRequest.
  ///
  /// In en, this message translates to:
  /// **'wants to connect with you.'**
  String get notificationContactRequest;

  /// No description provided for @notificationAcceptRequest.
  ///
  /// In en, this message translates to:
  /// **'is now connected with you.'**
  String get notificationAcceptRequest;

  /// No description provided for @notificationStoredMediaFile.
  ///
  /// In en, this message translates to:
  /// **'has stored your image.'**
  String get notificationStoredMediaFile;

  /// No description provided for @notificationReaction.
  ///
  /// In en, this message translates to:
  /// **'has reacted to your image.'**
  String get notificationReaction;

  /// No description provided for @notificationReopenedMedia.
  ///
  /// In en, this message translates to:
  /// **'has reopened your image.'**
  String get notificationReopenedMedia;

  /// No description provided for @notificationReactionToVideo.
  ///
  /// In en, this message translates to:
  /// **'has reacted with {reaction} to your video.'**
  String notificationReactionToVideo(Object reaction);

  /// No description provided for @notificationReactionToText.
  ///
  /// In en, this message translates to:
  /// **'has reacted with {reaction} to your message.'**
  String notificationReactionToText(Object reaction);

  /// No description provided for @notificationReactionToImage.
  ///
  /// In en, this message translates to:
  /// **'has reacted with {reaction} to your image.'**
  String notificationReactionToImage(Object reaction);

  /// No description provided for @notificationReactionToAudio.
  ///
  /// In en, this message translates to:
  /// **'has reacted with {reaction} to your audio message.'**
  String notificationReactionToAudio(Object reaction);

  /// No description provided for @notificationResponse.
  ///
  /// In en, this message translates to:
  /// **'has responded{inGroup}.'**
  String notificationResponse(Object inGroup);

  /// No description provided for @notificationTitleUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get notificationTitleUnknownUser;

  /// No description provided for @notificationCategoryMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationCategoryMessageTitle;

  /// No description provided for @notificationCategoryMessageDesc.
  ///
  /// In en, this message translates to:
  /// **'Messages from other users.'**
  String get notificationCategoryMessageDesc;

  /// No description provided for @groupContextMenuDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all messages in this chat.'**
  String get groupContextMenuDeleteGroup;

  /// No description provided for @groupYouAreNowLongerAMember.
  ///
  /// In en, this message translates to:
  /// **'You are no longer part of this group.'**
  String get groupYouAreNowLongerAMember;

  /// No description provided for @groupNetworkIssue.
  ///
  /// In en, this message translates to:
  /// **'Network issue. Try again later.'**
  String get groupNetworkIssue;

  /// No description provided for @leaveGroupSelectOtherAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Select another admin'**
  String get leaveGroupSelectOtherAdminTitle;

  /// No description provided for @leaveGroupSelectOtherAdminBody.
  ///
  /// In en, this message translates to:
  /// **'To leave the group, you must first select a new administrator.'**
  String get leaveGroupSelectOtherAdminBody;

  /// No description provided for @leaveGroupSureTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroupSureTitle;

  /// No description provided for @leaveGroupSureBody.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to leave the group?'**
  String get leaveGroupSureBody;

  /// No description provided for @leaveGroupSureOkBtn.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroupSureOkBtn;

  /// No description provided for @changeDisplayMaxTime.
  ///
  /// In en, this message translates to:
  /// **'Chats will now be deleted after {time} ({username}).'**
  String changeDisplayMaxTime(Object time, Object username);

  /// No description provided for @youChangedDisplayMaxTime.
  ///
  /// In en, this message translates to:
  /// **'Chats will now be deleted after {time}.'**
  String youChangedDisplayMaxTime(Object time);

  /// No description provided for @userGotReported.
  ///
  /// In en, this message translates to:
  /// **'User has been reported.'**
  String get userGotReported;

  /// No description provided for @deleteChatAfter.
  ///
  /// In en, this message translates to:
  /// **'Delete chat after...'**
  String get deleteChatAfter;

  /// No description provided for @deleteChatAfterAnHour.
  ///
  /// In en, this message translates to:
  /// **'one hour.'**
  String get deleteChatAfterAnHour;

  /// No description provided for @deleteChatAfterADay.
  ///
  /// In en, this message translates to:
  /// **'one day.'**
  String get deleteChatAfterADay;

  /// No description provided for @deleteChatAfterAWeek.
  ///
  /// In en, this message translates to:
  /// **'one week.'**
  String get deleteChatAfterAWeek;

  /// No description provided for @deleteChatAfterAMonth.
  ///
  /// In en, this message translates to:
  /// **'one month.'**
  String get deleteChatAfterAMonth;

  /// No description provided for @deleteChatAfterAYear.
  ///
  /// In en, this message translates to:
  /// **'one year.'**
  String get deleteChatAfterAYear;

  /// No description provided for @yourTwonlyScore.
  ///
  /// In en, this message translates to:
  /// **'Your twonly-Score'**
  String get yourTwonlyScore;

  /// No description provided for @registrationClosed.
  ///
  /// In en, this message translates to:
  /// **'Due to the current high volume of registrations, we have temporarily disabled registration to ensure that the service remains reliable. Please try again in a few days.'**
  String get registrationClosed;

  /// No description provided for @dialogAskDeleteMediaFilePopTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your masterpiece?'**
  String get dialogAskDeleteMediaFilePopTitle;

  /// No description provided for @dialogAskDeleteMediaFilePopDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogAskDeleteMediaFilePopDelete;

  /// No description provided for @allowErrorTracking.
  ///
  /// In en, this message translates to:
  /// **'Share errors and crashes with us'**
  String get allowErrorTracking;

  /// No description provided for @allowErrorTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If twonly crashes or errors occur, these are automatically reported to our self-hosted Glitchtip instance. Personal data such as messages or images are never uploaded.'**
  String get allowErrorTrackingSubtitle;

  /// No description provided for @avatarSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Would you like to save the changes?'**
  String get avatarSaveChanges;

  /// No description provided for @avatarSaveChangesStore.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get avatarSaveChangesStore;

  /// No description provided for @avatarSaveChangesDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get avatarSaveChangesDiscard;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
