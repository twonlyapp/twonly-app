// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get registerTitle => 'Welcome to twonly!';

  @override
  String get registerSlogan =>
      'twonly, a privacy friendly way to connect with friends through secure, spontaneous image sharing';

  @override
  String get onboardingWelcomeTitle => 'Welcome to twonly!';

  @override
  String get onboardingWelcomeBody =>
      'Experience a private and secure way to stay in touch with friends by sharing instant pictures.';

  @override
  String get onboardingE2eTitle => 'Carefree sharing';

  @override
  String get onboardingE2eBody =>
      'With end-to-end encryption, enjoy the peace of mind that only you and your friends can see the moments you share.';

  @override
  String get onboardingFocusTitle => 'Focus on sharing moments';

  @override
  String get onboardingFocusBody =>
      'Say goodbye to addictive features! twonly was created for sharing moments, free from useless distractions or ads.';

  @override
  String get onboardingSendTwonliesTitle => 'Send twonlies';

  @override
  String get onboardingSendTwonliesBody =>
      'Share moments securely with your partner. twonly ensures that only your partner can open it, keeping your moments with your partner a two(o)nly thing!';

  @override
  String get onboardingNotProductTitle => 'You are not the product!';

  @override
  String get onboardingNotProductBody =>
      'twonly is financed by a small monthly fee and not by selling your data.';

  @override
  String get onboardingBuyOneGetTwoTitle => 'Buy one get two';

  @override
  String get onboardingBuyOneGetTwoBody =>
      'twonly always requires at least two people, which is why you receive a second free license for your twonly partner with your purchase.';

  @override
  String get onboardingGetStartedTitle => 'Let\'s go!';

  @override
  String get onboardingGetStartedBody =>
      'You can test twonly free of charge in preview mode. In this mode you can be found by others and receive pictures or videos but you cannot send any yourself.';

  @override
  String get onboardingTryForFree => 'Try for free';

  @override
  String get registerUsernameSlogan =>
      'Please select a username so others can find you!';

  @override
  String get registerUsernameDecoration => 'Username';

  @override
  String get registerUsernameLimits =>
      'Username must be 3 to 12 characters long, consisting only of letters (a-z) and numbers (0-9).';

  @override
  String get registerSubmitButton => 'Register now!';

  @override
  String get registerTwonlyCodeText =>
      'Have you received a twonly code? Then redeem it either directly here or later!';

  @override
  String get registerTwonlyCodeLabel => 'twonly-Code';

  @override
  String get newMessageTitle => 'New message';

  @override
  String get chatsTapToSend => 'Click to send your first image';

  @override
  String get cameraPreviewSendTo => 'Send to';

  @override
  String get shareImageTitle => 'Share with';

  @override
  String get shareImageBestFriends => 'Best friends';

  @override
  String get shareImagePinnedContacts => 'Pinnded';

  @override
  String get shareImagedEditorSendImage => 'Send';

  @override
  String get shareImagedEditorShareWith => 'Share with';

  @override
  String get shareImagedEditorSaveImage => 'Save';

  @override
  String get shareImagedEditorSavedImage => 'Saved';

  @override
  String get shareImageSearchAllContacts => 'Search all contacts';

  @override
  String get shareImagedSelectAll => 'Select all';

  @override
  String get startNewChatTitle => 'Select Contact';

  @override
  String get startNewChatNewContact => 'New Contact';

  @override
  String get startNewChatYourContacts => 'Your Contacts';

  @override
  String get shareImageAllUsers => 'All contacts';

  @override
  String get shareImageAllTwonlyWarning =>
      'twonlies can only be send to verified contacts!';

  @override
  String get shareImageUserNotVerified => 'User is not verified';

  @override
  String get shareImageUserNotVerifiedDesc =>
      'twonlies can only be sent to verified users. To verify a user, go to their profile and to verify security number.';

  @override
  String get shareImageShowArchived => 'Show archived users';

  @override
  String get searchUsernameInput => 'Username';

  @override
  String get searchUsernameTitle => 'Search username';

  @override
  String get searchUserNamePreview =>
      'To protect you and other twonly users from spam and abuse, it is not possible to search for other people in preview mode. Other users can find you and their requests will be displayed here!';

  @override
  String get selectSubscription => 'Select subscription';

  @override
  String get searchUserNamePending => 'Pending';

  @override
  String get searchUserNameBlockUserTooltip =>
      'Block the user without informing.';

  @override
  String get searchUserNameRejectUserTooltip =>
      'Reject the request and let the requester know.';

  @override
  String get searchUserNameArchiveUserTooltip =>
      'Archive the user. He will appear again as soon as he accepts your request.';

  @override
  String get searchUsernameNotFound => 'Username not found';

  @override
  String searchUsernameNotFoundBody(Object username) {
    return 'There is no user with the username \"$username\" registered';
  }

  @override
  String get searchUsernameNewFollowerTitle => 'Follow requests';

  @override
  String get searchUsernameQrCodeBtn => 'Scan QR code';

  @override
  String get chatListViewSearchUserNameBtn => 'Add your first twonly contact!';

  @override
  String get chatListViewSendFirstTwonly => 'Send your first twonly!';

  @override
  String get chatListDetailInput => 'Type a message';

  @override
  String get userDeletedAccount => 'The user has deleted its account.';

  @override
  String get contextMenuUserProfile => 'User profile';

  @override
  String get contextMenuVerifyUser => 'Verify';

  @override
  String get contextMenuArchiveUser => 'Archive';

  @override
  String get contextMenuUndoArchiveUser => 'Undo archiving';

  @override
  String get contextMenuOpenChat => 'Open chat';

  @override
  String get contextMenuPin => 'Pin';

  @override
  String get contextMenuUnpin => 'Unpin';

  @override
  String get mediaViewerAuthReason => 'Please authenticate to see this twonly!';

  @override
  String get mediaViewerTwonlyTapToOpen => 'Tap to open your twonly!';

  @override
  String get messageSendState_Received => 'Received';

  @override
  String get messageSendState_Opened => 'Opened';

  @override
  String get messageSendState_Send => 'Sent';

  @override
  String get messageSendState_Sending => 'Sending';

  @override
  String get messageSendState_TapToLoad => 'Tap to load';

  @override
  String get messageSendState_Loading => 'Downloading';

  @override
  String get messageStoredInGalery => 'Stored in gallery';

  @override
  String get messageReopened => 'Re-opened';

  @override
  String get imageEditorDrawOk => 'Take drawing';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsChats => 'Chats';

  @override
  String get settingsPreSelectedReactions => 'Preselected reaction emojis';

  @override
  String get settingsPreSelectedReactionsError =>
      'A maximum of 12 reactions can be selected.';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsStorageData => 'Data and storage';

  @override
  String get settingsStorageDataStoreInGTitle => 'Store in Gallery';

  @override
  String get settingsStorageDataStoreInGSubtitle =>
      'Store saved images additional in the systems gallery.';

  @override
  String get settingsStorageDataMediaAutoDownload => 'Media auto-download';

  @override
  String get settingsStorageDataAutoDownMobile => 'When using mobile data';

  @override
  String get settingsStorageDataAutoDownWifi => 'When using WI-FI';

  @override
  String get settingsProfileCustomizeAvatar => 'Customize your avatar';

  @override
  String get settingsProfileEditDisplayName => 'Displayname';

  @override
  String get settingsProfileEditDisplayNameNew => 'New Displayname';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyBlockUsers => 'Block users';

  @override
  String get settingsPrivacyBlockUsersDesc =>
      'Blocked users will not be able to communicate with you. You can unblock a blocked user at any time.';

  @override
  String settingsPrivacyBlockUsersCount(Object len) {
    return '$len contact(s)';
  }

  @override
  String get settingsNotification => 'Notification';

  @override
  String get settingsNotifyTroubleshooting => 'Troubleshooting';

  @override
  String get settingsNotifyTroubleshootingDesc =>
      'Click here if you have problems receiving push notifications.';

  @override
  String get settingsNotifyTroubleshootingNoProblem => 'No problem detected';

  @override
  String get settingsNotifyTroubleshootingNoProblemDesc =>
      'Press OK to receive a test notification. When you receive no message even after waiting for 10 minutes, please send us your debug log in Settings > Help > Debug log, so we can look at that issue.';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsHelpDiagnostics => 'Diagnostic protocol';

  @override
  String get settingsHelpFAQ => 'FAQ';

  @override
  String get settingsHelpContactUs => 'Contact us';

  @override
  String get settingsHelpVersion => 'Version';

  @override
  String get settingsHelpLicenses => 'Licenses (Source-Code)';

  @override
  String get settingsHelpCredits => 'Licenses (Images)';

  @override
  String get settingsHelpImprint => 'Imprint & Privacy Policy';

  @override
  String get settingsHelpTerms => 'Terms of Service';

  @override
  String get settingsAppearanceTheme => 'Theme';

  @override
  String get settingsAccountDeleteAccount => 'Delete account';

  @override
  String settingsAccountDeleteAccountWithBallance(Object credit) {
    return 'In the next step, you can select what you want to to with the remaining credit ($credit).';
  }

  @override
  String get settingsAccountDeleteAccountNoBallance =>
      'Once you delete your account, there is no going back.';

  @override
  String get settingsAccountDeleteAccountNoInternet =>
      'An Internet connection is required to delete your account.';

  @override
  String get settingsAccountDeleteModalTitle => 'Are you sure?';

  @override
  String get settingsAccountDeleteModalBody =>
      'Your account will be deleted. There is no change to restore it.';

  @override
  String get contactVerifyNumberTitle => 'Verify safety number';

  @override
  String get contactVerifyNumberTapToScan => 'Tap to scan';

  @override
  String get contactVerifyNumberMarkAsVerified => 'Mark as verified';

  @override
  String get contactVerifyNumberClearVerification => 'Clear verification';

  @override
  String contactVerifyNumberLongDesc(Object username) {
    return 'To verify the end-to-end encryption with $username, compare the numbers with their device. The person can also scan your code with their device.';
  }

  @override
  String get contactNickname => 'Nickname';

  @override
  String get contactNicknameNew => 'New nickname';

  @override
  String get deleteAllContactMessages => 'Delete all text-messages';

  @override
  String deleteAllContactMessagesBody(Object username) {
    return 'This will remove all messages, except stored media files, in your chat with $username. This will NOT delete the messages stored at ${username}s device!';
  }

  @override
  String get contactBlock => 'Block';

  @override
  String contactBlockTitle(Object username) {
    return 'Block $username';
  }

  @override
  String get contactBlockBody =>
      'A blocked user will no longer be able to send you messages and their profile will be hidden from view. To unblock a user, simply navigate to Settings > Privacy > Blocked Users.';

  @override
  String get contactRemove => 'Remove user';

  @override
  String contactRemoveTitle(Object username) {
    return 'Remove $username';
  }

  @override
  String get contactRemoveBody =>
      'Remove the user and permanently delete the chat and all associated media files. This will also delete YOUR ACCOUNT FROM YOUR CONTACT\'S PHONE.';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get next => 'Next';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'Ok';

  @override
  String get switchFrontAndBackCamera =>
      'Switch between front and back camera.';

  @override
  String get addTextItem => 'Text';

  @override
  String get protectAsARealTwonly => 'Send as real twonly!';

  @override
  String get addDrawing => 'Drawing';

  @override
  String get addEmoji => 'Emoji';

  @override
  String get toggleFlashLight => 'Toggle the flash light';

  @override
  String get toggleHighQuality => 'Toggle better resolution';

  @override
  String get userFound => 'User found';

  @override
  String get userFoundBody => 'Do you want to create a follow request?';

  @override
  String searchUsernameNotFoundLong(Object username) {
    return '\"$username\" is not a twonly user. Please check the username and try again.';
  }

  @override
  String get errorUnknown =>
      'An unexpected error has occurred. Please try again later.';

  @override
  String get errorBadRequest =>
      'The request could not be understood by the server due to malformed syntax. Please check your input and try again.';

  @override
  String get errorTooManyRequests =>
      'You have made too many requests in a short period. Please wait a moment before trying again.';

  @override
  String get errorInternalError =>
      'The server is currently not available. Please try again later.';

  @override
  String get errorInvalidInvitationCode =>
      'The invitation code you provided is invalid. Please check the code and try again.';

  @override
  String get errorUsernameAlreadyTaken =>
      'The username you want to use is already taken. Please choose a different username.';

  @override
  String get errorSignatureNotValid =>
      'The provided signature is not valid. Please check your credentials and try again.';

  @override
  String get errorUsernameNotFound =>
      'The username you entered does not exist. Please check the spelling or create a new account.';

  @override
  String get errorUsernameNotValid =>
      'The username you provided does not meet the required criteria. Please choose a valid username.';

  @override
  String get errorInvalidPublicKey =>
      'The public key you provided is invalid. Please check the key and try again.';

  @override
  String get errorSessionAlreadyAuthenticated =>
      'You are already logged in. Please log out if you want to log in with a different account.';

  @override
  String get errorSessionNotAuthenticated =>
      'Your session is not authenticated. Please log in to continue.';

  @override
  String get errorOnlyOneSessionAllowed =>
      'Only one active session is allowed per user. Please log out from other devices to continue.';

  @override
  String get errorNotEnoughCredit => 'You do not have enough twonly-credit.';

  @override
  String get errorVoucherInvalid =>
      'The voucher code you entered is not valid.';

  @override
  String get errorPlanLimitReached =>
      'You have reached your plans limit. Please upgrade your plan.';

  @override
  String get errorPlanNotAllowed =>
      'This feature is not available in your current plan.';

  @override
  String get errorPlanUpgradeNotYearly =>
      'The plan upgrade must be paid for annually, as the current plan is also billed annually.';

  @override
  String get upgradeToPaidPlan => 'Upgrade to a paid plan.';

  @override
  String upgradeToPaidPlanButton(Object planId) {
    return 'Upgrade subscription to $planId';
  }

  @override
  String partOfPaidPlanOf(Object username) {
    return 'You are part of the paid plan of $username!';
  }

  @override
  String get year => 'year';

  @override
  String get month => 'month';

  @override
  String get proFeature1 => '✓ Unlimited media file uploads';

  @override
  String get proFeature2 => '1 additional Plus user';

  @override
  String get proFeature3 => '3 additional Free users';

  @override
  String get familyFeature1 => '✓ Unlimited media file uploads';

  @override
  String get familyFeature2 => '4 additional Plus users';

  @override
  String get familyFeature3 => '4 additional Free users';

  @override
  String get redeemUserInviteCode => 'Or redeem a twonly-Code.';

  @override
  String get redeemUserInviteCodeTitle => 'Redeem twonly-Code';

  @override
  String get redeemUserInviteCodeSuccess =>
      'Your plan has been successfully adjusted.';

  @override
  String get freeFeature1 => '3 Media file uploads per day';

  @override
  String get plusFeature1 => '✓ Unlimited media file uploads';

  @override
  String get transactionHistory => 'Your transaction history';

  @override
  String get manageSubscription => 'Manage your subscription';

  @override
  String get nextPayment => 'Next payment';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get manageAdditionalUsers => 'Manage additional users';

  @override
  String get open => 'Open';

  @override
  String get createOrRedeemVoucher => 'Buy or redeem voucher';

  @override
  String get createVoucher => 'Buy voucher';

  @override
  String get createVoucherDesc =>
      'Choose the value of the voucher. The value of the voucher will be deducted from your twonly balance.';

  @override
  String get redeemVoucher => 'Redeem voucher';

  @override
  String get openVouchers => 'Open vouchers';

  @override
  String get voucherCreated => 'Voucher created';

  @override
  String get voucherRedeemed => 'Voucher redeemed';

  @override
  String get enterVoucherCode => 'Enter Voucher Code';

  @override
  String get requestedVouchers => 'Requested vouchers';

  @override
  String get redeemedVouchers => 'Redeemed vouchers';

  @override
  String get buy => 'Buy';

  @override
  String subscriptionRefund(Object refund) {
    return 'When you upgrade, you will receive a refund of $refund for your current subscription.';
  }

  @override
  String get transactionCash => 'Cash transaction';

  @override
  String get transactionPlanUpgrade => 'Plan upgrade';

  @override
  String get transactionRefund => 'Refund transaction';

  @override
  String get transactionThanksForTesting => 'Thank you for testing';

  @override
  String get transactionUnknown => 'Unknown transaction';

  @override
  String get transactionVoucherCreated => 'Voucher created';

  @override
  String get transactionVoucherRedeemed => 'Voucher redeemed';

  @override
  String get transactionAutoRenewal => 'Automatic renewal';

  @override
  String get checkoutOptions => 'Options';

  @override
  String get refund => 'Refund';

  @override
  String get checkoutPayYearly => 'Pay yearly';

  @override
  String get checkoutTotal => 'Total';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get twonlyCredit => 'twonly-Credit';

  @override
  String get notEnoughCredit => 'You do not have enough credit!';

  @override
  String get chargeCredit => 'Charge credit';

  @override
  String get autoRenewal => 'Auto renewal';

  @override
  String get autoRenewalDesc => 'You can change this at any time.';

  @override
  String get autoRenewalLongDesc =>
      'When your subscription expires, you will automatically be downgraded to the Preview plan. If you activate the automatic renewal, please make sure that you have enough credit for the automatic renewal.  We will notify you in good time before the automatic renewal.';

  @override
  String get planSuccessUpgraded => 'Successfully upgraded your plan.';

  @override
  String get checkoutSubmit => 'Order with a fee.';

  @override
  String get additionalUsersList => 'Your additional users';

  @override
  String get additionalUsersPlusTokens => 'twonly-Codes für \"Plus\" user';

  @override
  String get additionalUsersFreeTokens => 'twonly-Codes für \"Free\" user';

  @override
  String get planLimitReached =>
      'You have reached your plan limit for today. Upgrade your plan now to send the media file.';

  @override
  String get planNotAllowed =>
      'You cannot send media files with your current tariff.  Upgrade your plan now to send the media file.';

  @override
  String get galleryDelete => 'Delete file';

  @override
  String get galleryDetails => 'Show details';

  @override
  String get settingsResetTutorials => 'Show tutorials again';

  @override
  String get settingsResetTutorialsDesc =>
      'Click here to show already displayed tutorials again.';

  @override
  String get settingsResetTutorialsSuccess =>
      'Tutorials will be displayed again.';

  @override
  String get tutorialChatListSearchUsersTitle =>
      'Find Friends and Manage Friend Requests';

  @override
  String get tutorialChatListSearchUsersDesc =>
      'If you know your friends\' usernames, you can search for them here and send a friend request. You will also see all requests from other users that you can accept or block.';

  @override
  String get tutorialChatListContextMenuTitle =>
      'Long press on the contact to open the context menu.';

  @override
  String get tutorialChatListContextMenuDesc =>
      'With the context menu, you can pin, archive, and perform various actions on your contacts. Simply long press the contact and then move your finger to the desired option or tap directly on it.';

  @override
  String get tutorialChatMessagesVerifyShieldTitle => 'Verify your contacts!';

  @override
  String get tutorialChatMessagesVerifyShieldDesc =>
      'twonly uses the Signal protocol for secure end-to-end encryption. When you first contact someone, their public identity key is downloaded. To ensure that this key has not been tampered with by third parties, you should compare it with your friend when you meet in person. Once you have verified the user, you can also enable the twonly mode when sending images and videos.';

  @override
  String get tutorialChatMessagesReopenMessageTitle =>
      'Reopen Images and Videos';

  @override
  String get tutorialChatMessagesReopenMessageDesc =>
      'If your friend has sent you a picture or video with infinite display time, you can open it again at any time until you restart the app. To do this, simply double-click on the message. Your friend will then receive a notification that you have viewed the picture again.';

  @override
  String get memoriesEmpty =>
      'As soon as you save pictures or videos, they end up here in your memories.';
}
