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
      'twonly is financed by donations and an optional subscription. Your data will never be sold.';

  @override
  String get onboardingGetStartedTitle => 'Let\'s go!';

  @override
  String get registerUsernameSlogan =>
      'Please select a username so others can find you!';

  @override
  String get registerUsernameDecoration => 'Username';

  @override
  String get registerUsernameLimits =>
      'Your username must be at least 3 characters long.';

  @override
  String get registerProofOfWorkFailed =>
      'There was an issue with the captcha test. Please try again.';

  @override
  String get registerSubmitButton => 'Register now!';

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
  String get startNewChatSearchHint => 'Name, username or groupname';

  @override
  String get shareImagedSelectAll => 'Select all';

  @override
  String get startNewChatTitle => 'Select Contact';

  @override
  String get startNewChatNewContact => 'New Contact';

  @override
  String get shareImageAllUsers => 'All contacts';

  @override
  String get shareImageShowArchived => 'Show archived users';

  @override
  String get searchUsernameInput => 'Username';

  @override
  String get addFriendTitle => 'Add friends';

  @override
  String get searchUserNamePending => 'Request pending';

  @override
  String get searchUsernameNotFound => 'Username not found';

  @override
  String searchUsernameNotFoundBody(Object username) {
    return 'There is no user with the username \"$username\" registered';
  }

  @override
  String get searchUsernameNewFollowerTitle => 'Open requests';

  @override
  String get chatListViewSearchUserNameBtn => 'Add your first twonly contact!';

  @override
  String get chatListDetailInput => 'Type a message';

  @override
  String get userDeletedAccount => 'The user has deleted their account.';

  @override
  String get contextMenuUserProfile => 'User profile';

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
  String get contextMenuViewAgain => 'View again';

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
  String get messageStoredInGallery => 'Stored in gallery';

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
  String get settingsAccount => 'Account';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsPrivacy => 'Privacy & Security';

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
      'Press OK to receive a test notification. If you do not receive the test notification, please click on the new menu item that appears after you click “OK”.';

  @override
  String get settingsNotifyResetTitle => 'Didn\'t receive a test notification?';

  @override
  String get settingsNotifyResetTitleSubtitle =>
      'If you haven\'t received any test notifications, click here to reset your notification tokens.';

  @override
  String get settingsNotifyResetTitleReset =>
      'Your notification tokens have been reset.';

  @override
  String get settingsNotifyResetTitleResetDesc =>
      'If the problem persists, please send us your debug log via Settings > Help so we can investigate the issue.';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsHelpDiagnostics => 'Diagnostic protocol';

  @override
  String get settingsHelpFAQ => 'FAQ';

  @override
  String get feedbackTooltip => 'Give Feedback to improve twonly.';

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
  String get contactUsFaq => 'Have you read our FAQ yet?';

  @override
  String get contactUsEmojis => 'How do you feel? (optional)';

  @override
  String get contactUsSelectOption => 'Please select an option';

  @override
  String get contactUsReason => 'Tell us why you\'re reaching out';

  @override
  String get contactUsMessage =>
      'If you want to receive an answer, please add your e-mail address so we can contact you.';

  @override
  String get contactUsYourMessage => 'Your message';

  @override
  String get contactUsMessageTitle => 'Tell us what\'s going on';

  @override
  String get contactUsReasonNotWorking => 'Something\'s not working';

  @override
  String get contactUsReasonFeatureRequest => 'Feature request';

  @override
  String get contactUsReasonQuestion => 'Question';

  @override
  String get contactUsReasonFeedback => 'Feedback';

  @override
  String get contactUsReasonOther => 'Other';

  @override
  String get contactUsIncludeLog => 'Include debug log';

  @override
  String get contactUsWhatsThat => 'What\'s that?';

  @override
  String get contactUsLastWarning =>
      'This are the information\'s which will be send to us. Please verify them and then press submit.';

  @override
  String get contactUsSuccess => 'Feedback submitted successfully!';

  @override
  String get contactUsShortcut => 'Hide Feedback Icon';

  @override
  String get settingsHelpTerms => 'Terms of Service';

  @override
  String get settingsAppearanceTheme => 'Theme';

  @override
  String get settingsAccountDeleteAccount => 'Delete account';

  @override
  String get settingsAccountDeleteAccountNoBallance =>
      'Once you delete your account, there is no going back.';

  @override
  String get settingsAccountDeleteModalTitle => 'Are you sure?';

  @override
  String get settingsAccountDeleteModalBody =>
      'Your account will be deleted. There is no change to restore it.';

  @override
  String get contactVerifyNumberTitle => 'Verify contact';

  @override
  String get userVerifiedTitle => 'User verified';

  @override
  String contactVerifiedBy(Object username) {
    return 'Verified by $username';
  }

  @override
  String get verificationTypeQrScanned => 'You scanned their QR code.';

  @override
  String get verificationTypeSecretQrToken =>
      'The other person scanned your QR code.';

  @override
  String get verificationTypeLink => 'Verified via link.';

  @override
  String get verificationTypeContactSharedByVerified =>
      'Contact received from a verified contact.';

  @override
  String get verificationTypeMigratedFromOldVersion =>
      'Migrated from old version.';

  @override
  String get contactViewMessage => 'Message';

  @override
  String get contactNickname => 'Nickname';

  @override
  String get contactNicknameNew => 'New nickname';

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
      'Permanently remove the user. If the user tries to send you a new message, you will have to accept the user again first.';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get next => 'Next';

  @override
  String get finishSetup => 'Complete setup';

  @override
  String get submit => 'Submit';

  @override
  String get close => 'Close';

  @override
  String get disable => 'Disable';

  @override
  String get enable => 'Enable';

  @override
  String get cancel => 'Cancel';

  @override
  String get now => 'Now';

  @override
  String get you => 'You';

  @override
  String get minutesShort => 'min.';

  @override
  String get image => 'Image';

  @override
  String get video => 'Video';

  @override
  String get react => 'React';

  @override
  String get reply => 'Reply';

  @override
  String get copy => 'Copy';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get info => 'Info';

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
  String userFound(Object username) {
    return '$username found';
  }

  @override
  String get userFoundBody => 'Do you want to create a follow request?';

  @override
  String get errorInternalError =>
      'The server is currently not available. Please try again later.';

  @override
  String get errorInvalidInvitationCode =>
      'The invitation code you provided is invalid. Please check the code and try again.';

  @override
  String get errorUsernameAlreadyTaken => 'The username is already taken.';

  @override
  String get errorUsernameNotValid =>
      'The username you provided does not meet the required criteria. Please choose a valid username.';

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
  String upgradeToPaidPlanButton(Object planId, Object sufix) {
    return 'Upgrade to $planId$sufix';
  }

  @override
  String partOfPaidPlanOf(Object username) {
    return 'You are part of the paid plan of $username!';
  }

  @override
  String get year => 'year';

  @override
  String get yearly => 'Yearly';

  @override
  String get month => 'month';

  @override
  String get monthly => 'Monthly';

  @override
  String get proFeature1 => '✓ Unlimited media file uploads';

  @override
  String get proFeature2 => '✓ 1 additional Plus user';

  @override
  String get proFeature3 => '✓ Restore flames';

  @override
  String get proFeature4 => '✓ Support twonly';

  @override
  String get familyFeature1 => '✓ Unlimited media file uploads';

  @override
  String get familyFeature2 => '✓ 4 additional Plus user';

  @override
  String get familyFeature3 => '✓ Restore flames';

  @override
  String get familyFeature4 => '✓ Support twonly';

  @override
  String get freeFeature1 => '✓ 10 Media file uploads per day';

  @override
  String get plusFeature1 => '✓ Unlimited media file uploads';

  @override
  String get plusFeature2 => '✓ Additional features (coming-soon)';

  @override
  String get manageAdditionalUsers => 'Manage additional users';

  @override
  String get open => 'Open';

  @override
  String get createVoucher => 'Buy voucher';

  @override
  String get redeemVoucher => 'Redeem voucher';

  @override
  String get buy => 'Buy';

  @override
  String get autoRenewal => 'Auto renewal';

  @override
  String get additionalUsersList => 'Your additional users';

  @override
  String get galleryDelete => 'Delete file';

  @override
  String get galleryDetails => 'Show details';

  @override
  String get galleryExport => 'Export to gallery';

  @override
  String get galleryExportSuccess => 'Successfully saved in the Gallery.';

  @override
  String get memoriesEmpty =>
      'As soon as you save pictures or videos, they end up here in your memories.';

  @override
  String get deleteTitle => 'Are you sure?';

  @override
  String get deleteOkBtnForAll => 'Delete for all';

  @override
  String get deleteOkBtnForMe => 'Delete for me';

  @override
  String get deleteImageTitle => 'Are you sure?';

  @override
  String get deleteImageBody => 'The image will be irrevocably deleted.';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get backupPending => 'Pending';

  @override
  String get backupFailed => 'Failed';

  @override
  String get backupSuccess => 'Success';

  @override
  String get backupTwonlySafeDesc =>
      'Back up your twonly identity, as this is the only way to restore your account if you uninstall the app or lose your phone.';

  @override
  String get backupNoPasswordRecovery =>
      'Due to twonly\'s security system, there is (currently) no password recovery function. Therefore, you must remember your password or, better yet, write it down.';

  @override
  String get backupServer => 'Server';

  @override
  String get backupMaxBackupSize => 'max. backup size';

  @override
  String get backupStorageRetention => 'Storage retention';

  @override
  String get backupLastBackupDate => 'Last backup';

  @override
  String get backupLastBackupSize => 'Backup size';

  @override
  String get backupLastBackupResult => 'Result';

  @override
  String get backupData => 'Data-Backup';

  @override
  String get backupInsecurePassword => 'Insecure password';

  @override
  String get backupInsecurePasswordDesc =>
      'The chosen password is very insecure and can therefore easily be guessed by attackers. Please choose a secure password.';

  @override
  String get backupInsecurePasswordOk => 'Continue anyway';

  @override
  String get backupInsecurePasswordCancel => 'Try again';

  @override
  String get backupTwonlySafeLongDesc =>
      'twonly does not have any central user accounts. A key pair is created during installation, which consists of a public and a private key. The private key is only stored on your device to protect it from unauthorized access. The public key is uploaded to the server and linked to your chosen username so that others can find you.\n\ntwonly Backup regularly creates an encrypted, anonymous backup of your private key together with your contacts and settings. Your username and chosen password are enough to restore this data on another device.';

  @override
  String get backupSelectStrongPassword =>
      'Choose a secure password. This is required if you want to restore your twonly Backup.';

  @override
  String get password => 'Password';

  @override
  String get passwordRepeated => 'Repeat password';

  @override
  String get passwordRepeatedNotEqual => 'Passwords do not match.';

  @override
  String get backupPasswordRequirement =>
      'Password must be at least 8 characters long.';

  @override
  String get backupExpertSettings => 'Expert settings';

  @override
  String get backupEnableBackup => 'Activate automatic backup';

  @override
  String get backupOwnServerDesc =>
      'Save your twonly Backup at twonly or on any server of your choice.';

  @override
  String get backupUseOwnServer => 'Use server';

  @override
  String get backupResetServer => 'Use standard server';

  @override
  String get backupTwonlySaveNow => 'Save now';

  @override
  String get backupChangePassword => 'Change password';

  @override
  String get twonlySafeRecoverTitle => 'Recovery';

  @override
  String get twonlySafeRecoverDesc =>
      'If you have created a backup with twonly Backup, you can restore it here.';

  @override
  String get twonlySafeRecoverBtn => 'Restore backup';

  @override
  String get inviteFriends => 'Invite your friends';

  @override
  String get inviteFriendsShareBtn => 'Share';

  @override
  String inviteFriendsShareText(Object url) {
    return 'Let\'s switch to twonly: $url';
  }

  @override
  String get appOutdated => 'Your version of twonly is out of date.';

  @override
  String get appOutdatedBtn => 'Update Now';

  @override
  String get doubleClickToReopen => 'Double-click\nto open again';

  @override
  String get uploadLimitReached =>
      'The upload limit has\nbeen reached. Upgrade to Pro\nor wait until tomorrow.';

  @override
  String get fileLimitReached => 'Maximum file size\nexceeded';

  @override
  String get retransmissionRequested => 'Retransmission requested';

  @override
  String get openChangeLog => 'Open changelog automatically';

  @override
  String reportUserTitle(Object username) {
    return 'Report $username';
  }

  @override
  String get reportUserReason => 'Reporting reason';

  @override
  String get reportUser => 'Report user';

  @override
  String get newDeviceRegistered =>
      'You have logged in on another device. You have therefore been logged out here.';

  @override
  String get tabToRemoveEmoji => 'Tab to remove';

  @override
  String get quotedMessageWasDeleted => 'The quoted message has been deleted.';

  @override
  String get messageWasDeleted => 'Message has been deleted.';

  @override
  String get messageWasDeletedShort => 'Deleted';

  @override
  String get sent => 'Delivered';

  @override
  String get sentTo => 'Delivered to';

  @override
  String get received => 'Received';

  @override
  String get opened => 'Opened';

  @override
  String get waitingForInternet => 'Waiting for internet';

  @override
  String get editHistory => 'Edit history';

  @override
  String get archivedChats => 'Archived chats';

  @override
  String get durationShortSecond => 'Sec.';

  @override
  String get durationShortMinute => 'Min.';

  @override
  String get durationShortHour => 'Hrs.';

  @override
  String durationShortDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String get contacts => 'Contacts';

  @override
  String get groups => 'Groups';

  @override
  String get newGroup => 'New group';

  @override
  String get selectMembers => 'Select members';

  @override
  String get selectGroupName => 'Select group name';

  @override
  String get groupNameInput => 'Group name';

  @override
  String get groupMembers => 'Members';

  @override
  String get addMember => 'Add member';

  @override
  String get createGroup => 'Create group';

  @override
  String get leaveGroup => 'Leave group';

  @override
  String get createContactRequest => 'Create contact request';

  @override
  String get contactRequestSend => 'Contact request send';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get removeAdmin => 'Remove as admin';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get admin => 'Admin';

  @override
  String revokeAdminRightsTitle(Object username) {
    return 'Revoke $username\'s admin rights?';
  }

  @override
  String get revokeAdminRightsOkBtn => 'Remove as admin';

  @override
  String makeAdminRightsTitle(Object username) {
    return 'Make $username an admin?';
  }

  @override
  String makeAdminRightsBody(Object username) {
    return '$username will be able to edit this group and its members.';
  }

  @override
  String get makeAdminRightsOkBtn => 'Make admin';

  @override
  String get updateGroup => 'Update group';

  @override
  String get alreadyInGroup => 'Already in Group';

  @override
  String removeContactFromGroupTitle(Object username) {
    return 'Remove $username from this group?';
  }

  @override
  String youChangedGroupName(Object newGroupName) {
    return 'You have changed the group name to \"$newGroupName\".';
  }

  @override
  String makerChangedGroupName(Object maker, Object newGroupName) {
    return '$maker has changed the group name to \"$newGroupName\".';
  }

  @override
  String get youCreatedGroup => 'You have created the group.';

  @override
  String makerCreatedGroup(Object maker) {
    return '$maker has created the group.';
  }

  @override
  String youRemovedMember(Object affected) {
    return 'You have removed $affected from the group.';
  }

  @override
  String makerRemovedMember(Object affected, Object maker) {
    return '$maker has removed $affected from the group.';
  }

  @override
  String youAddedMember(Object affected) {
    return 'You have added $affected to the group.';
  }

  @override
  String makerAddedMember(Object affected, Object maker) {
    return '$maker has added $affected to the group.';
  }

  @override
  String youMadeAdmin(Object affected) {
    return 'You made $affected an admin.';
  }

  @override
  String makerMadeAdmin(Object affected, Object maker) {
    return '$maker made $affected an admin.';
  }

  @override
  String youRevokedAdminRights(Object affectedR) {
    return 'You revoked $affectedR\'s admin rights.';
  }

  @override
  String makerRevokedAdminRights(Object affectedR, Object maker) {
    return '$maker revoked $affectedR\'s admin rights.';
  }

  @override
  String get youLeftGroup => 'You have left the group.';

  @override
  String makerLeftGroup(Object maker) {
    return '$maker has left the group.';
  }

  @override
  String get groupActionYou => 'you';

  @override
  String get groupActionYour => 'your';

  @override
  String get notificationFillerIn => 'in';

  @override
  String notificationText(Object inGroup) {
    return 'sent a message$inGroup.';
  }

  @override
  String notificationTwonly(Object inGroup) {
    return 'sent a twonly$inGroup.';
  }

  @override
  String notificationVideo(Object inGroup) {
    return 'sent a video$inGroup.';
  }

  @override
  String notificationImage(Object inGroup) {
    return 'sent an image$inGroup.';
  }

  @override
  String notificationAudio(Object inGroup) {
    return 'sent a voice message$inGroup.';
  }

  @override
  String notificationAddedToGroup(Object groupname) {
    return 'has added you to \"$groupname\"';
  }

  @override
  String get notificationContactRequest => 'wants to connect with you.';

  @override
  String get notificationContactRequestUnknownUser =>
      'have received a new contact request.';

  @override
  String get notificationAcceptRequest => 'is now connected with you.';

  @override
  String get notificationStoredMediaFile => 'has stored your image.';

  @override
  String get notificationReaction => 'has reacted to your image.';

  @override
  String get notificationReopenedMedia => 'has reopened your image.';

  @override
  String notificationReactionToVideo(Object reaction) {
    return 'has reacted with $reaction to your video.';
  }

  @override
  String notificationReactionToText(Object reaction) {
    return 'has reacted with $reaction to your message.';
  }

  @override
  String notificationReactionToImage(Object reaction) {
    return 'has reacted with $reaction to your image.';
  }

  @override
  String notificationReactionToAudio(Object reaction) {
    return 'has reacted with $reaction to your audio message.';
  }

  @override
  String notificationResponse(Object inGroup) {
    return 'has responded$inGroup.';
  }

  @override
  String get notificationTitleUnknown => 'You have a new message.';

  @override
  String get notificationBodyUnknown => 'Open twonly to learn more.';

  @override
  String get notificationCategoryMessageTitle => 'Messages';

  @override
  String get notificationCategoryMessageDesc => 'Messages from other users.';

  @override
  String get groupContextMenuDeleteGroup =>
      'This will permanently delete all messages in this chat.';

  @override
  String get groupYouAreNowLongerAMember =>
      'You are no longer part of this group.';

  @override
  String get groupNetworkIssue => 'Network issue. Try again later.';

  @override
  String get leaveGroupSelectOtherAdminTitle => 'Select another admin';

  @override
  String get leaveGroupSelectOtherAdminBody =>
      'To leave the group, you must first select a new administrator.';

  @override
  String get leaveGroupSureTitle => 'Leave group';

  @override
  String get leaveGroupSureBody => 'Do you really want to leave the group?';

  @override
  String get leaveGroupSureOkBtn => 'Leave group';

  @override
  String changeDisplayMaxTime(Object time, Object username) {
    return 'Chats will now be deleted after $time ($username).';
  }

  @override
  String youChangedDisplayMaxTime(Object time) {
    return 'Chats will now be deleted after $time.';
  }

  @override
  String get userGotReported => 'User has been reported.';

  @override
  String get deleteChatAfter => 'Delete chat after...';

  @override
  String get deleteChatAfterAnHour => 'one hour.';

  @override
  String get deleteChatAfterADay => 'one day.';

  @override
  String get deleteChatAfterAWeek => 'one week.';

  @override
  String get deleteChatAfterAMonth => 'one month.';

  @override
  String get deleteChatAfterAYear => 'one year.';

  @override
  String get yourTwonlyScore => 'Your twonly-Score';

  @override
  String get registrationClosed =>
      'Due to the current high volume of registrations, we have temporarily disabled registration to ensure that the service remains reliable. Please try again in a few days.';

  @override
  String get dialogAskDeleteMediaFilePopTitle =>
      'Are you sure you want to delete your masterpiece?';

  @override
  String get dialogAskDeleteMediaFilePopDelete => 'Delete';

  @override
  String get allowErrorTracking => 'Share errors and crashes with us';

  @override
  String get allowErrorTrackingSubtitle =>
      'If twonly crashes or errors occur, these are automatically reported to our self-hosted Glitchtip instance. Personal data such as messages or images are never uploaded.';

  @override
  String get avatarSaveChanges => 'Would you like to save the changes?';

  @override
  String get avatarSaveChangesStore => 'Save';

  @override
  String get avatarSaveChangesDiscard => 'Discard';

  @override
  String get inProcess => 'In process';

  @override
  String get draftMessage => 'Draft';

  @override
  String get exportMemories => 'Export memories (Beta)';

  @override
  String get importMemories => 'Import memories (Beta)';

  @override
  String get voiceMessageSlideToCancel => 'Slide to cancel';

  @override
  String get voiceMessageCancel => 'Cancel';

  @override
  String get shareYourProfile => 'Share your profile';

  @override
  String get scanOtherProfile => 'Scan other profile';

  @override
  String get openYourOwnQRcode => 'Open your own QR code';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get finishSetupCardTitle => 'Complete your profile';

  @override
  String get finishSetupCardDesc =>
      'You are almost there! Finish setting up your account to get the most out of twonly.';

  @override
  String get finishSetupCardAction => 'Resume Setup';

  @override
  String get onboardingFinishLater => 'Finish later';

  @override
  String get onboardingProfileTitle => 'Choose your look';

  @override
  String get onboardingProfileBody =>
      'Select an avatar and a display name that friends will see.';

  @override
  String get onboardingBackupBody =>
      'Back up your twonly identity, as this is the only way to restore your account if you uninstall the app or lose your phone.';

  @override
  String get onboardingVerificationBadgeTitle => 'Verification Badge';

  @override
  String get onboardingUserDiscoveryShareFriends => 'Share your friends';

  @override
  String get onboardingUserDiscoveryShareFriendsDesc =>
      'Share with your friends who you know and who you have verified. Friends can *only see mutual friends* from your friend list. You can change your mind at *any time* or *hide specific people*.';

  @override
  String get onboardingUserDiscoveryContactsVerifiedBadge =>
      'Contacts verified by your friends get a badge';

  @override
  String get onboardingUserDiscoveryWhoIsRequesting =>
      'Be informed about who is requesting';

  @override
  String get userDiscoverySettingsManualApproval => 'Manual approval';

  @override
  String get userDiscoverySettingsManualApprovalDesc =>
      'Before someone is shared, you\'ll be asked first.';

  @override
  String get onboardingUserDiscoveryLetFriendsFindYou =>
      'Let your friends find you';

  @override
  String get onboardingUserDiscoveryBeRecommended => 'Be recommended to others';

  @override
  String get onboardingUserDiscoveryWhatOthersSee => 'What others will see';

  @override
  String get onboardingUserDiscoveryWhatYouSee =>
      'If requested, that\'s what you will see';

  @override
  String get onboardingAddContactsTitle => 'Add new contacts';

  @override
  String get onboardingAddContactsAcceptDesc =>
      'In twonly, every contact must first be accepted before you can communicate.';

  @override
  String get onboardingAddContactsMethodHeading => 'Add contacts';

  @override
  String get onboardingAddContactsMethodScan => 'Scan the contact\'s QR code.';

  @override
  String get onboardingAddContactsMethodSearch => 'Search for the username.';

  @override
  String get onboardingAddContactsMethodShare => 'Share a contact in chats.';

  @override
  String linkFromUsername(Object username) {
    return 'Is the link from $username?';
  }

  @override
  String get linkFromUsernameLong =>
      'If you received the link from your friend, you can mark the user as verified, as the public key in the link matches the public key already stored for that user?';

  @override
  String get gotLinkFromFriend => 'Yes, I got the link from my friend!';

  @override
  String couldNotVerifyUsername(Object username) {
    return 'Could not verify $username';
  }

  @override
  String get linkPubkeyDoesNotMatch =>
      'The public key in the link does not match the public key stored for this contact. Try to meet your friend in person and scan the QR code directly!';

  @override
  String get startWithCameraOpen => 'Start with camera open';

  @override
  String get showImagePreviewWhenSending =>
      'Display image preview when selecting recipients';

  @override
  String verifiedPublicKey(Object username) {
    return 'The public key of $username has been verified and is valid.';
  }

  @override
  String get memoriesAYearAgo => 'One year ago';

  @override
  String memoriesXYearsAgo(Object years) {
    return '$years years ago';
  }

  @override
  String migrationOfMemories(Object open) {
    return 'Migration of media files: $open still to be processed.';
  }

  @override
  String get autoStoreAllSendUnlimitedMediaFiles => 'Save all sent media';

  @override
  String get autoStoreAllSendUnlimitedMediaFilesSubtitle =>
      'If you enable this option, all images you send will be saved as long as they were sent with an infinite countdown and not in twonly mode.';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String additionalUserAddError(Object username) {
    return '$username could not be added, please try again later.';
  }

  @override
  String additionalUserAddErrorNotInFreePlan(Object username) {
    return '$username is already on a paid plan and therefore could not be added.';
  }

  @override
  String additionalUserAddButton(Object limit, Object used) {
    return 'Add additional user ($used/$limit)';
  }

  @override
  String get additionalUserRemoveTitle => 'Remove this additional user';

  @override
  String get additionalUserRemoveDesc =>
      'After removal, the additional user will automatically be downgraded to the free plan, and you can add another person.';

  @override
  String get additionalUserSelectTitle => 'Select additional users';

  @override
  String additionalUserSelectButton(Object limit, Object used) {
    return 'Select users ($used/$limit)';
  }

  @override
  String get storeAsDefault => 'Store as default';

  @override
  String get deleteUserErrorMessage =>
      'You can only delete the contact once the direct chat has been deleted and the contact is no longer a member of a group.';

  @override
  String groupSizeLimitError(Object size) {
    return 'Currently, group size is limited to $size people!';
  }

  @override
  String get authRequestReopenImage =>
      'You must authenticate to reopen the image.';

  @override
  String get shareContactsMenu => 'Contact';

  @override
  String get shareContactsTitle => 'Select contacts';

  @override
  String get shareContactsSubmit => 'Share now';

  @override
  String get updateTwonlyMessage =>
      'To see this message, you need to update twonly.';

  @override
  String get verificationBadgeNote =>
      'You can verify your friends by scanning their public QR code. Click to learn more.';

  @override
  String get verificationBadgeTitle => 'Verification';

  @override
  String get verificationBadgeGeneralDesc =>
      'The checkmark gives you the certainty that you are messaging the right person. Scan the contact\'s QR code to verify it.';

  @override
  String get verificationBadgeGreenDesc =>
      'A contact you have *personally* verified.';

  @override
  String get verificationBadgeYellowDesc =>
      'A contact who has been verified by at least one of *your contacts*.';

  @override
  String get verificationBadgeRedDesc =>
      'A contact whose identity has *not* yet been verified.';

  @override
  String chatEntryFlameRestored(Object count) {
    return '$count flames restored';
  }

  @override
  String requestedUserToastText(Object username) {
    return '$username was successfully requested.';
  }

  @override
  String get profileYourQrCode => 'Your QR code';

  @override
  String get settingsScreenLock => 'Screen lock';

  @override
  String get settingsScreenLockSubtitle =>
      'To open twonly, you\'ll need to use your smartphone\'s unlock feature.';

  @override
  String get settingsScreenLockAuthMessageEnable =>
      'Use the screen lock from twonly.';

  @override
  String get settingsScreenLockAuthMessageDisable =>
      'Disable the screen lock from twonly.';

  @override
  String get unlockTwonly => 'Unlock twonly';

  @override
  String get unlockTwonlyTryAgain => 'Try again';

  @override
  String get unlockTwonlyDesc =>
      'Use your phone\'s unlock settings to unlock twonly';

  @override
  String get settingsTypingIndication => 'Typing Indicators';

  @override
  String get settingsTypingIndicationSubtitle =>
      'When the typing indicator is turned off, you can\'t see when others are typing a message.';

  @override
  String get scanQrOrShow => 'Scan / Show QR';

  @override
  String get contactActionBlock => 'Block';

  @override
  String get contactActionAccept => 'Accept';

  @override
  String get userDiscoverySettingsMutualFriends =>
      'Choose how many mutual friends a person must have for you to be suggested to them.';

  @override
  String get userDiscoverySettingsApply => 'Apply changes';

  @override
  String get userDiscoveryEnabledDisableWarning =>
      'If you disable the \"Mutual Friends\" feature, you will no longer see suggestions. You will also stop sharing your friends with new contacts.';

  @override
  String get userDiscoveryEnabledChangeSettings => 'Change settings';

  @override
  String get userDiscoveryEnabledFaq =>
      'In our FAQ we explain how the \"Mutual Friends\" feature works.';

  @override
  String get userDiscoveryDisabledIntro =>
      'twonly does *not* collect your phone number or needs access to your contacts. Instead, twonly can *find your friends through mutual friends*.';

  @override
  String get userDiscoverySettingsTitle => 'Mutual Friends';

  @override
  String get userDiscoveryDisabledLearnMore => 'Learn more';

  @override
  String get userDiscoveryEnabledDialogTitle => 'Really disable?';

  @override
  String get userDiscoveryEnabledFriendsShared => 'Friends you share';

  @override
  String get userDiscoveryEnabledFriendsSharedDesc =>
      'You only share friends who have also activated this feature and who have reached the threshold you set.';

  @override
  String get userDiscoverySettingsCurrentlyDisabled =>
      'The feature \"Mutual Friends\" is currently disabled.';

  @override
  String get userDiscoveryEnabledNoFriendsShared =>
      'You are not sharing anyone yet.';

  @override
  String get userDiscoveryActionDisable => 'Disable';

  @override
  String get friendSuggestionsTitle => 'Friend suggestions';

  @override
  String get andWord => 'and';

  @override
  String friendSuggestionsFriendsWith(Object friends) {
    return 'Friends with $friends.';
  }

  @override
  String friendSuggestionsGroupMemberIn(Object groups) {
    return ' Group member in $groups.';
  }

  @override
  String get friendSuggestionsRequest => 'Request';

  @override
  String contactUserDiscoveryImagesLeft(Object imagesLeft, Object username) {
    return '$imagesLeft more images are needed until your friends are shared with $username.';
  }

  @override
  String userDiscoveryEnabledVersion(Object version) {
    return 'Version: $version';
  }

  @override
  String userDiscoveryEnabledYourVersion(Object version) {
    return 'Your version: $version';
  }

  @override
  String get userDiscoveryEnabledStopSharing => 'Stop sharing';

  @override
  String userDiscoveryManualApprovalReachedThreshold(Object username) {
    return '$username has reached your threshold and now needs your manual approval to be shared with your friends.';
  }

  @override
  String get userDiscoveryManualApprovalHideContact => 'Hide contact';

  @override
  String get userDiscoveryManualApprovalShareContact => 'Share contact';

  @override
  String onboardingSetupCompleteTitle(Object username) {
    return 'You\'re all set, $username!';
  }

  @override
  String get onboardingSetupCompleteDesc =>
      'You can now share your moments with your friends securely without distractions like ads.';
}
