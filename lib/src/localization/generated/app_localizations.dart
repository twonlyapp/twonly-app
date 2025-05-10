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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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
  /// **'twonly is financed by a small monthly fee and not by selling your data.'**
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
  /// **'Username must be 3 to 12 characters long, consisting only of letters (a-z) and numbers (0-9).'**
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

  /// No description provided for @messageStoredInGalery.
  ///
  /// In en, this message translates to:
  /// **'Stored in gallery'**
  String get messageStoredInGalery;

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

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get settingsHelpSupport;

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

  /// No description provided for @settingsHelpLegal.
  ///
  /// In en, this message translates to:
  /// **'Imprint, Terms & Privacy Policy'**
  String get settingsHelpLegal;

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
  /// **'Delete all messages'**
  String get deleteAllContactMessages;

  /// No description provided for @deleteAllContactMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all messages in your chat with {username}. This will NOT delete the messages stored at {username}s device!'**
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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

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
  /// **'The username you want to use is already taken. Please choose a different username.'**
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
  /// **'3 additional Free users'**
  String get proFeature3;

  /// No description provided for @familyFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ Unlimited media file uploads'**
  String get familyFeature1;

  /// No description provided for @familyFeature2.
  ///
  /// In en, this message translates to:
  /// **'4 additional Plus users'**
  String get familyFeature2;

  /// No description provided for @familyFeature3.
  ///
  /// In en, this message translates to:
  /// **'5 additional Free users'**
  String get familyFeature3;

  /// No description provided for @redeemUserInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Or redeem an additional user invite code.'**
  String get redeemUserInviteCode;

  /// No description provided for @freeFeature1.
  ///
  /// In en, this message translates to:
  /// **'3 Media file uploads per day'**
  String get freeFeature1;

  /// No description provided for @plusFeature1.
  ///
  /// In en, this message translates to:
  /// **'✓ Unlimited media file uploads'**
  String get plusFeature1;

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
  /// **'Manage your additional users'**
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

  /// No description provided for @selectPaymentMethode.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethode;

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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
