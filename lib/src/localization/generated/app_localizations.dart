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
    Locale('en'),
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

  /// No description provided for @onboardingGetStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get onboardingGetStartedTitle;

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

  /// No description provided for @registerProofOfWorkFailed.
  ///
  /// In en, this message translates to:
  /// **'There was an issue with the captcha test. Please try again.'**
  String get registerProofOfWorkFailed;

  /// No description provided for @registerSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Register now!'**
  String get registerSubmitButton;

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

  /// No description provided for @shareImageAllUsers.
  ///
  /// In en, this message translates to:
  /// **'All contacts'**
  String get shareImageAllUsers;

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

  /// No description provided for @addFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Add friends'**
  String get addFriendTitle;

  /// No description provided for @searchUserNamePending.
  ///
  /// In en, this message translates to:
  /// **'Request pending'**
  String get searchUserNamePending;

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
  /// **'Open requests'**
  String get searchUsernameNewFollowerTitle;

  /// No description provided for @chatListViewSearchUserNameBtn.
  ///
  /// In en, this message translates to:
  /// **'Add your first twonly contact!'**
  String get chatListViewSearchUserNameBtn;

  /// No description provided for @chatListDetailInput.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get chatListDetailInput;

  /// No description provided for @userDeletedAccount.
  ///
  /// In en, this message translates to:
  /// **'The user has deleted their account.'**
  String get userDeletedAccount;

  /// No description provided for @contextMenuUserProfile.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get contextMenuUserProfile;

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

  /// No description provided for @contextMenuViewAgain.
  ///
  /// In en, this message translates to:
  /// **'View again'**
  String get contextMenuViewAgain;

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
  /// **'Account'**
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
  /// **'Privacy & Security'**
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
  /// **'Press OK to receive a test notification. If you do not receive the test notification, please click on the new menu item that appears after you click “OK”.'**
  String get settingsNotifyTroubleshootingNoProblemDesc;

  /// No description provided for @settingsNotifyResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive a test notification?'**
  String get settingsNotifyResetTitle;

  /// No description provided for @settingsNotifyResetTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you haven\'t received any test notifications, click here to reset your notification tokens.'**
  String get settingsNotifyResetTitleSubtitle;

  /// No description provided for @settingsNotifyResetTitleReset.
  ///
  /// In en, this message translates to:
  /// **'Your notification tokens have been reset.'**
  String get settingsNotifyResetTitleReset;

  /// No description provided for @settingsNotifyResetTitleResetDesc.
  ///
  /// In en, this message translates to:
  /// **'If the problem persists, please send us your debug log via Settings > Help so we can investigate the issue.'**
  String get settingsNotifyResetTitleResetDesc;

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

  /// No description provided for @settingsAccountDeleteAccountNoBallance.
  ///
  /// In en, this message translates to:
  /// **'Once you delete your account, there is no going back.'**
  String get settingsAccountDeleteAccountNoBallance;

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
  /// **'Verify contact'**
  String get contactVerifyNumberTitle;

  /// No description provided for @userVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'User verified'**
  String get userVerifiedTitle;

  /// No description provided for @contactVerifiedBy.
  ///
  /// In en, this message translates to:
  /// **'Verified by {username}'**
  String contactVerifiedBy(Object username);

  /// No description provided for @verificationTypeQrScanned.
  ///
  /// In en, this message translates to:
  /// **'You scanned their QR code.'**
  String get verificationTypeQrScanned;

  /// No description provided for @verificationTypeSecretQrToken.
  ///
  /// In en, this message translates to:
  /// **'The other person scanned your QR code.'**
  String get verificationTypeSecretQrToken;

  /// No description provided for @verificationTypeLink.
  ///
  /// In en, this message translates to:
  /// **'Verified via link.'**
  String get verificationTypeLink;

  /// No description provided for @verificationTypeContactSharedByVerified.
  ///
  /// In en, this message translates to:
  /// **'Contact received from a verified contact.'**
  String get verificationTypeContactSharedByVerified;

  /// No description provided for @verificationTypeMigratedFromOldVersion.
  ///
  /// In en, this message translates to:
  /// **'Migrated from old version.'**
  String get verificationTypeMigratedFromOldVersion;

  /// No description provided for @contactViewMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactViewMessage;

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
  /// **'Permanently remove the user. If the user tries to send you a new message, you will have to accept the user again first.'**
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

  /// No description provided for @finishSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete setup'**
  String get finishSetup;

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

  /// No description provided for @userFound.
  ///
  /// In en, this message translates to:
  /// **'{username} found'**
  String userFound(Object username);

  /// No description provided for @userFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to create a follow request?'**
  String get userFoundBody;

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

  /// No description provided for @errorUsernameNotValid.
  ///
  /// In en, this message translates to:
  /// **'The username you provided does not meet the required criteria. Please choose a valid username.'**
  String get errorUsernameNotValid;

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
  /// **'Upgrade to {planId}{sufix}'**
  String upgradeToPaidPlanButton(Object planId, Object sufix);

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

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @proFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ Unlimited media file uploads'**
  String get proFeature1;

  /// No description provided for @proFeature2.
  ///
  /// In en, this message translates to:
  /// **'✓ 1 additional Plus user'**
  String get proFeature2;

  /// No description provided for @proFeature3.
  ///
  /// In en, this message translates to:
  /// **'✓ Restore flames'**
  String get proFeature3;

  /// No description provided for @proFeature4.
  ///
  /// In en, this message translates to:
  /// **'✓ Support twonly'**
  String get proFeature4;

  /// No description provided for @familyFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ Unlimited media file uploads'**
  String get familyFeature1;

  /// No description provided for @familyFeature2.
  ///
  /// In en, this message translates to:
  /// **'✓ 4 additional Plus user'**
  String get familyFeature2;

  /// No description provided for @familyFeature3.
  ///
  /// In en, this message translates to:
  /// **'✓ Restore flames'**
  String get familyFeature3;

  /// No description provided for @familyFeature4.
  ///
  /// In en, this message translates to:
  /// **'✓ Support twonly'**
  String get familyFeature4;

  /// No description provided for @freeFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ 10 Media file uploads per day'**
  String get freeFeature1;

  /// No description provided for @plusFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ Unlimited media file uploads'**
  String get plusFeature1;

  /// No description provided for @plusFeature2.
  ///
  /// In en, this message translates to:
  /// **'✓ Additional features (coming-soon)'**
  String get plusFeature2;

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

  /// No description provided for @createVoucher.
  ///
  /// In en, this message translates to:
  /// **'Buy voucher'**
  String get createVoucher;

  /// No description provided for @redeemVoucher.
  ///
  /// In en, this message translates to:
  /// **'Redeem voucher'**
  String get redeemVoucher;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @autoRenewal.
  ///
  /// In en, this message translates to:
  /// **'Auto renewal'**
  String get autoRenewal;

  /// No description provided for @additionalUsersList.
  ///
  /// In en, this message translates to:
  /// **'Your additional users'**
  String get additionalUsersList;

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

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Data-Backup'**
  String get backupData;

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
  /// **'The upload limit has\nbeen reached. Upgrade to Pro\nor wait until tomorrow.'**
  String get uploadLimitReached;

  /// No description provided for @fileLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum file size\nexceeded'**
  String get fileLimitReached;

  /// No description provided for @retransmissionRequested.
  ///
  /// In en, this message translates to:
  /// **'Retransmission requested'**
  String get retransmissionRequested;

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
  /// **'You revoked {affectedR}\'s admin rights.'**
  String youRevokedAdminRights(Object affectedR);

  /// No description provided for @makerRevokedAdminRights.
  ///
  /// In en, this message translates to:
  /// **'{maker} revoked {affectedR}\'s admin rights.'**
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
  /// **'sent an image{inGroup}.'**
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

  /// No description provided for @notificationContactRequestUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'have received a new contact request.'**
  String get notificationContactRequestUnknownUser;

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

  /// No description provided for @notificationTitleUnknown.
  ///
  /// In en, this message translates to:
  /// **'You have a new message.'**
  String get notificationTitleUnknown;

  /// No description provided for @notificationBodyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Open twonly to learn more.'**
  String get notificationBodyUnknown;

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

  /// No description provided for @inProcess.
  ///
  /// In en, this message translates to:
  /// **'In process'**
  String get inProcess;

  /// No description provided for @draftMessage.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftMessage;

  /// No description provided for @exportMemories.
  ///
  /// In en, this message translates to:
  /// **'Export memories (Beta)'**
  String get exportMemories;

  /// No description provided for @importMemories.
  ///
  /// In en, this message translates to:
  /// **'Import memories (Beta)'**
  String get importMemories;

  /// No description provided for @voiceMessageSlideToCancel.
  ///
  /// In en, this message translates to:
  /// **'Slide to cancel'**
  String get voiceMessageSlideToCancel;

  /// No description provided for @voiceMessageCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get voiceMessageCancel;

  /// No description provided for @shareYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Share your profile'**
  String get shareYourProfile;

  /// No description provided for @scanOtherProfile.
  ///
  /// In en, this message translates to:
  /// **'Scan other profile'**
  String get scanOtherProfile;

  /// No description provided for @openYourOwnQRcode.
  ///
  /// In en, this message translates to:
  /// **'Open your own QR code'**
  String get openYourOwnQRcode;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @finishSetupCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get finishSetupCardTitle;

  /// No description provided for @finishSetupCardDesc.
  ///
  /// In en, this message translates to:
  /// **'You are almost there! Finish setting up your account to get the most out of twonly.'**
  String get finishSetupCardDesc;

  /// No description provided for @finishSetupCardAction.
  ///
  /// In en, this message translates to:
  /// **'Resume Setup'**
  String get finishSetupCardAction;

  /// No description provided for @onboardingFinishLater.
  ///
  /// In en, this message translates to:
  /// **'Finish later'**
  String get onboardingFinishLater;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your look'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Select an avatar and a display name that friends will see.'**
  String get onboardingProfileBody;

  /// No description provided for @onboardingBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Back up your twonly identity, as this is the only way to restore your account if you uninstall the app or lose your phone.'**
  String get onboardingBackupBody;

  /// No description provided for @onboardingVerificationBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Badge'**
  String get onboardingVerificationBadgeTitle;

  /// No description provided for @onboardingUserDiscoveryShareFriends.
  ///
  /// In en, this message translates to:
  /// **'Share your friends'**
  String get onboardingUserDiscoveryShareFriends;

  /// No description provided for @onboardingUserDiscoveryIncreaseTrust.
  ///
  /// In en, this message translates to:
  /// **'Increase trust'**
  String get onboardingUserDiscoveryIncreaseTrust;

  /// No description provided for @onboardingUserDiscoveryShareFriendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Share with your friends who you know and who you have verified. Friends can *only see mutual friends* from your friend list.'**
  String get onboardingUserDiscoveryShareFriendsDesc;

  /// No description provided for @onboardingUserDiscoveryContactsVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Contacts verified by your friends get a badge'**
  String get onboardingUserDiscoveryContactsVerifiedBadge;

  /// No description provided for @onboardingUserDiscoveryWhoIsRequesting.
  ///
  /// In en, this message translates to:
  /// **'Be informed about who is requesting'**
  String get onboardingUserDiscoveryWhoIsRequesting;

  /// No description provided for @userDiscoverySettingsEnableAllContacts.
  ///
  /// In en, this message translates to:
  /// **'Enabled for all contacts'**
  String get userDiscoverySettingsEnableAllContacts;

  /// No description provided for @userDiscoverySettingsManualApproval.
  ///
  /// In en, this message translates to:
  /// **'Manual approval'**
  String get userDiscoverySettingsManualApproval;

  /// No description provided for @userDiscoverySettingsManualApprovalDesc.
  ///
  /// In en, this message translates to:
  /// **'Before sharing someone, you will be asked every time someone reaches the number of send images.'**
  String get userDiscoverySettingsManualApprovalDesc;

  /// No description provided for @onboardingUserDiscoveryLetFriendsFindYou.
  ///
  /// In en, this message translates to:
  /// **'Let your friends find you'**
  String get onboardingUserDiscoveryLetFriendsFindYou;

  /// No description provided for @onboardingUserDiscoveryLetFriendsFindYouDesc.
  ///
  /// In en, this message translates to:
  /// **'To help your friends find you, *you can be suggested* to people with whom you have *mutual friends*.'**
  String get onboardingUserDiscoveryLetFriendsFindYouDesc;

  /// No description provided for @onboardingUserDiscoveryBeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Be recommended to others'**
  String get onboardingUserDiscoveryBeRecommended;

  /// No description provided for @onboardingUserDiscoveryWhatOthersSee.
  ///
  /// In en, this message translates to:
  /// **'What others will see'**
  String get onboardingUserDiscoveryWhatOthersSee;

  /// No description provided for @onboardingUserDiscoveryWhatYouSee.
  ///
  /// In en, this message translates to:
  /// **'If requested, that\'s what you will see'**
  String get onboardingUserDiscoveryWhatYouSee;

  /// No description provided for @onboardingAddContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add new contacts'**
  String get onboardingAddContactsTitle;

  /// No description provided for @onboardingAddContactsAcceptDesc.
  ///
  /// In en, this message translates to:
  /// **'In twonly, every contact must first be accepted before you can communicate.'**
  String get onboardingAddContactsAcceptDesc;

  /// No description provided for @onboardingAddContactsMethodHeading.
  ///
  /// In en, this message translates to:
  /// **'Add contacts'**
  String get onboardingAddContactsMethodHeading;

  /// No description provided for @onboardingAddContactsMethodScan.
  ///
  /// In en, this message translates to:
  /// **'Scan the contact\'s QR code.'**
  String get onboardingAddContactsMethodScan;

  /// No description provided for @onboardingAddContactsMethodSearch.
  ///
  /// In en, this message translates to:
  /// **'Search for the username.'**
  String get onboardingAddContactsMethodSearch;

  /// No description provided for @onboardingAddContactsMethodShare.
  ///
  /// In en, this message translates to:
  /// **'Share a contact in chats.'**
  String get onboardingAddContactsMethodShare;

  /// No description provided for @linkFromUsername.
  ///
  /// In en, this message translates to:
  /// **'Is the link from {username}?'**
  String linkFromUsername(Object username);

  /// No description provided for @linkFromUsernameLong.
  ///
  /// In en, this message translates to:
  /// **'If you received the link from your friend, you can mark the user as verified, as the public key in the link matches the public key already stored for that user?'**
  String get linkFromUsernameLong;

  /// No description provided for @gotLinkFromFriend.
  ///
  /// In en, this message translates to:
  /// **'Yes, I got the link from my friend!'**
  String get gotLinkFromFriend;

  /// No description provided for @couldNotVerifyUsername.
  ///
  /// In en, this message translates to:
  /// **'Could not verify {username}'**
  String couldNotVerifyUsername(Object username);

  /// No description provided for @linkPubkeyDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The public key in the link does not match the public key stored for this contact. Try to meet your friend in person and scan the QR code directly!'**
  String get linkPubkeyDoesNotMatch;

  /// No description provided for @startWithCameraOpen.
  ///
  /// In en, this message translates to:
  /// **'Start with camera open'**
  String get startWithCameraOpen;

  /// No description provided for @showImagePreviewWhenSending.
  ///
  /// In en, this message translates to:
  /// **'Display image preview when selecting recipients'**
  String get showImagePreviewWhenSending;

  /// No description provided for @verifiedPublicKey.
  ///
  /// In en, this message translates to:
  /// **'The public key of {username} has been verified and is valid.'**
  String verifiedPublicKey(Object username);

  /// No description provided for @memoriesAYearAgo.
  ///
  /// In en, this message translates to:
  /// **'One year ago'**
  String get memoriesAYearAgo;

  /// No description provided for @memoriesXYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{years} years ago'**
  String memoriesXYearsAgo(Object years);

  /// No description provided for @migrationOfMemories.
  ///
  /// In en, this message translates to:
  /// **'Migration of media files: {open} still to be processed.'**
  String migrationOfMemories(Object open);

  /// No description provided for @autoStoreAllSendUnlimitedMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'Save all sent media'**
  String get autoStoreAllSendUnlimitedMediaFiles;

  /// No description provided for @autoStoreAllSendUnlimitedMediaFilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If you enable this option, all images you send will be saved as long as they were sent with an infinite countdown and not in twonly mode.'**
  String get autoStoreAllSendUnlimitedMediaFilesSubtitle;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @additionalUserAddError.
  ///
  /// In en, this message translates to:
  /// **'{username} could not be added, please try again later.'**
  String additionalUserAddError(Object username);

  /// No description provided for @additionalUserAddErrorNotInFreePlan.
  ///
  /// In en, this message translates to:
  /// **'{username} is already on a paid plan and therefore could not be added.'**
  String additionalUserAddErrorNotInFreePlan(Object username);

  /// No description provided for @additionalUserAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add additional user ({used}/{limit})'**
  String additionalUserAddButton(Object limit, Object used);

  /// No description provided for @additionalUserRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this additional user'**
  String get additionalUserRemoveTitle;

  /// No description provided for @additionalUserRemoveDesc.
  ///
  /// In en, this message translates to:
  /// **'After removal, the additional user will automatically be downgraded to the free plan, and you can add another person.'**
  String get additionalUserRemoveDesc;

  /// No description provided for @additionalUserSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select additional users'**
  String get additionalUserSelectTitle;

  /// No description provided for @additionalUserSelectButton.
  ///
  /// In en, this message translates to:
  /// **'Select users ({used}/{limit})'**
  String additionalUserSelectButton(Object limit, Object used);

  /// No description provided for @storeAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Store as default'**
  String get storeAsDefault;

  /// No description provided for @deleteUserErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'You can only delete the contact once the direct chat has been deleted and the contact is no longer a member of a group.'**
  String get deleteUserErrorMessage;

  /// No description provided for @groupSizeLimitError.
  ///
  /// In en, this message translates to:
  /// **'Currently, group size is limited to {size} people!'**
  String groupSizeLimitError(Object size);

  /// No description provided for @authRequestReopenImage.
  ///
  /// In en, this message translates to:
  /// **'You must authenticate to reopen the image.'**
  String get authRequestReopenImage;

  /// No description provided for @shareContactsMenu.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get shareContactsMenu;

  /// No description provided for @shareContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select contacts'**
  String get shareContactsTitle;

  /// No description provided for @shareContactsSubmit.
  ///
  /// In en, this message translates to:
  /// **'Share now'**
  String get shareContactsSubmit;

  /// No description provided for @updateTwonlyMessage.
  ///
  /// In en, this message translates to:
  /// **'To see this message, you need to update twonly.'**
  String get updateTwonlyMessage;

  /// No description provided for @verificationBadgeNote.
  ///
  /// In en, this message translates to:
  /// **'You can verify your friends by scanning their public QR code. Click to learn more.'**
  String get verificationBadgeNote;

  /// No description provided for @verificationBadgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationBadgeTitle;

  /// No description provided for @verificationBadgeGeneralDesc.
  ///
  /// In en, this message translates to:
  /// **'The checkmark gives you the certainty that you are messaging the right person. Scan the contact\'s QR code to verify it.'**
  String get verificationBadgeGeneralDesc;

  /// No description provided for @verificationBadgeGreenDesc.
  ///
  /// In en, this message translates to:
  /// **'A contact you have *personally* verified.'**
  String get verificationBadgeGreenDesc;

  /// No description provided for @verificationBadgeYellowDesc.
  ///
  /// In en, this message translates to:
  /// **'A contact who has been verified by at least one of *your contacts*.'**
  String get verificationBadgeYellowDesc;

  /// No description provided for @verificationBadgeRedDesc.
  ///
  /// In en, this message translates to:
  /// **'A contact whose identity has *not* yet been verified.'**
  String get verificationBadgeRedDesc;

  /// No description provided for @chatEntryFlameRestored.
  ///
  /// In en, this message translates to:
  /// **'{count} flames restored'**
  String chatEntryFlameRestored(Object count);

  /// No description provided for @requestedUserToastText.
  ///
  /// In en, this message translates to:
  /// **'{username} was successfully requested.'**
  String requestedUserToastText(Object username);

  /// No description provided for @profileYourQrCode.
  ///
  /// In en, this message translates to:
  /// **'Your QR code'**
  String get profileYourQrCode;

  /// No description provided for @settingsScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Screen lock'**
  String get settingsScreenLock;

  /// No description provided for @settingsScreenLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To open twonly, you\'ll need to use your smartphone\'s unlock feature.'**
  String get settingsScreenLockSubtitle;

  /// No description provided for @settingsScreenLockAuthMessageEnable.
  ///
  /// In en, this message translates to:
  /// **'Use the screen lock from twonly.'**
  String get settingsScreenLockAuthMessageEnable;

  /// No description provided for @settingsScreenLockAuthMessageDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable the screen lock from twonly.'**
  String get settingsScreenLockAuthMessageDisable;

  /// No description provided for @unlockTwonly.
  ///
  /// In en, this message translates to:
  /// **'Unlock twonly'**
  String get unlockTwonly;

  /// No description provided for @unlockTwonlyTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get unlockTwonlyTryAgain;

  /// No description provided for @unlockTwonlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your phone\'s unlock settings to unlock twonly'**
  String get unlockTwonlyDesc;

  /// No description provided for @settingsTypingIndication.
  ///
  /// In en, this message translates to:
  /// **'Typing Indicators'**
  String get settingsTypingIndication;

  /// No description provided for @settingsTypingIndicationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When the typing indicator is turned off, you can\'t see when others are typing a message.'**
  String get settingsTypingIndicationSubtitle;

  /// No description provided for @scanQrOrShow.
  ///
  /// In en, this message translates to:
  /// **'Scan / Show QR'**
  String get scanQrOrShow;

  /// No description provided for @contactActionBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get contactActionBlock;

  /// No description provided for @contactActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get contactActionAccept;

  /// No description provided for @userDiscoverySettingsMinImages.
  ///
  /// In en, this message translates to:
  /// **'Choose the minimum number of images you must have send to a person before you securely share your friends with them.'**
  String get userDiscoverySettingsMinImages;

  /// No description provided for @userDiscoverySettingsMutualFriends.
  ///
  /// In en, this message translates to:
  /// **'Choose how many mutual friends a person must have for you to be suggested to them.'**
  String get userDiscoverySettingsMutualFriends;

  /// No description provided for @userDiscoverySettingsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get userDiscoverySettingsApply;

  /// No description provided for @userDiscoveryEnabledDisableWarning.
  ///
  /// In en, this message translates to:
  /// **'If you disable the \"Share your friends\" feature, you will no longer see suggestions. You will also stop sharing your friends with new contacts.'**
  String get userDiscoveryEnabledDisableWarning;

  /// No description provided for @userDiscoveryEnabledChangeSettings.
  ///
  /// In en, this message translates to:
  /// **'Change settings'**
  String get userDiscoveryEnabledChangeSettings;

  /// No description provided for @userDiscoveryEnabledFaq.
  ///
  /// In en, this message translates to:
  /// **'In our FAQ we explain how the \"Share your friends\" feature works.'**
  String get userDiscoveryEnabledFaq;

  /// No description provided for @userDiscoveryDisabledIntro.
  ///
  /// In en, this message translates to:
  /// **'twonly does *not* collect your phone number or needs access to your contacts. Instead, twonly can *find your friends through mutual friends*.'**
  String get userDiscoveryDisabledIntro;

  /// No description provided for @userDiscoveryDisabledDecide.
  ///
  /// In en, this message translates to:
  /// **'Decide for yourself who can see your friends. You can change your mind at *any time* or *hide specific people*.'**
  String get userDiscoveryDisabledDecide;

  /// No description provided for @userDiscoverySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your friends'**
  String get userDiscoverySettingsTitle;

  /// No description provided for @userDiscoverySettingsMinImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Number of images send'**
  String get userDiscoverySettingsMinImagesTitle;

  /// No description provided for @userDiscoverySettingsMutualFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Number of mutual friends'**
  String get userDiscoverySettingsMutualFriendsTitle;

  /// No description provided for @userDiscoveryDisabledYouHaveControl.
  ///
  /// In en, this message translates to:
  /// **'You are in control'**
  String get userDiscoveryDisabledYouHaveControl;

  /// No description provided for @userDiscoveryDisabledLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get userDiscoveryDisabledLearnMore;

  /// No description provided for @userDiscoveryEnabledDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Really disable?'**
  String get userDiscoveryEnabledDialogTitle;

  /// No description provided for @userDiscoveryEnabledFriendsShared.
  ///
  /// In en, this message translates to:
  /// **'Friends you share'**
  String get userDiscoveryEnabledFriendsShared;

  /// No description provided for @userDiscoveryEnabledFriendsSharedDesc.
  ///
  /// In en, this message translates to:
  /// **'You only share friends who have also activated this feature and who have reached the threshold you set.'**
  String get userDiscoveryEnabledFriendsSharedDesc;

  /// No description provided for @userDiscoverySettingsCurrentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'The feature \"Share your friends\" is currently disabled.'**
  String get userDiscoverySettingsCurrentlyDisabled;

  /// No description provided for @userDiscoveryEnabledNoFriendsShared.
  ///
  /// In en, this message translates to:
  /// **'You are not sharing anyone yet.'**
  String get userDiscoveryEnabledNoFriendsShared;

  /// No description provided for @userDiscoveryActionDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get userDiscoveryActionDisable;

  /// No description provided for @friendSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend suggestions'**
  String get friendSuggestionsTitle;

  /// No description provided for @andWord.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get andWord;

  /// No description provided for @friendSuggestionsFriendsWith.
  ///
  /// In en, this message translates to:
  /// **'Friends with {friends}.'**
  String friendSuggestionsFriendsWith(Object friends);

  /// No description provided for @friendSuggestionsGroupMemberIn.
  ///
  /// In en, this message translates to:
  /// **' Group member in {groups}.'**
  String friendSuggestionsGroupMemberIn(Object groups);

  /// No description provided for @friendSuggestionsRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get friendSuggestionsRequest;

  /// No description provided for @contactUserDiscoveryImagesLeft.
  ///
  /// In en, this message translates to:
  /// **'{imagesLeft} more images are needed until your friends are shared with {username}.'**
  String contactUserDiscoveryImagesLeft(Object imagesLeft, Object username);

  /// No description provided for @userDiscoveryEnabledVersion.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String userDiscoveryEnabledVersion(Object version);

  /// No description provided for @userDiscoveryEnabledYourVersion.
  ///
  /// In en, this message translates to:
  /// **'Your version: {version}'**
  String userDiscoveryEnabledYourVersion(Object version);

  /// No description provided for @userDiscoveryEnabledStopSharing.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get userDiscoveryEnabledStopSharing;

  /// No description provided for @userDiscoveryManualApprovalReachedThreshold.
  ///
  /// In en, this message translates to:
  /// **'{username} has reached your threshold and now needs your manual approval to be shared with your friends.'**
  String userDiscoveryManualApprovalReachedThreshold(Object username);

  /// No description provided for @userDiscoveryManualApprovalHideContact.
  ///
  /// In en, this message translates to:
  /// **'Hide contact'**
  String get userDiscoveryManualApprovalHideContact;

  /// No description provided for @userDiscoveryManualApprovalShareContact.
  ///
  /// In en, this message translates to:
  /// **'Share contact'**
  String get userDiscoveryManualApprovalShareContact;
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
    'that was used.',
  );
}
