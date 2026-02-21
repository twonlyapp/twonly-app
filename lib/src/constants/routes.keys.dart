class Routes {
  static const String home = '/';
  static const String chats = '/chats';
  static const String chatsAddNewUser = '/chats/add_new_user';
  static const String chatsArchived = '/chats/archived';
  static const String chatsStartNewChat = '/chats/start_new_chat';
  static const String chatsCameraSendTo = '/chats/camera_send_to';
  static const String chatsMediaViewer = '/chats/media_viewer';
  static const String chatsMessages = '/chats/messages';

  static String groupCreateSelectMember(String? groupId) =>
      '/group/create/select_member${groupId == null ? '' : '/$groupId'}';

  static String profileGroup(String groupId) => '/profile/group/$groupId';
  static String profileContact(int contactId) => '/profile/contact/$contactId';

  static const String cameraQRScanner = '/camera/qr_scanner';

  static const String settings = '/settings';
  static const String settingsProfile = '/settings/profile';
  static const String settingsPublicProfile = '/settings/public_profile';
  static const String settingsProfileModifyAvatar =
      '/settings/profile/modify_avatar';
  static const String settingsAccount = '/settings/account';
  static const String settingsSubscription = '/settings/subscription';
  static const String settingsBackup = '/settings/backup';
  static const String settingsBackupServer = '/settings/backup/server';
  static const String settingsBackupRecovery = '/settings/backup/recovery';
  static const String settingsBackupSetup = '/settings/backup/setup';
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsChats = '/settings/chats';
  static const String settingsChatsReactions = '/settings/chats/reactions';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsPrivacyBlockUsers =
      '/settings/privacy/block_users';
  static const String settingsNotification = '/settings/notification';
  static const String settingsStorage = '/settings/storage_data';
  static const String settingsStorageImport = '/settings/storage_data/import';
  static const String settingsStorageExport = '/settings/storage_data/export';
  static const String settingsHelp = '/settings/help';
  static const String settingsHelpFaq = '/settings/help/faq';
  static const String settingsHelpFaqVerifyBadge =
      '/settings/help/faq/verifybadge';
  static const String settingsHelpContactUs = '/settings/help/contact_us';
  static const String settingsHelpDiagnostics = '/settings/help/diagnostics';
  static const String settingsHelpUserStudy = '/settings/help/user_study';
  static const String settingsHelpUserStudyQuestionnaire =
      '/settings/help/user_study/questionnaire';
  static const String settingsHelpCredits = '/settings/help/credits';
  static const String settingsHelpChangelog = '/settings/help/changelog';
  static const String settingsDeveloper = '/settings/developer';
  static const String settingsDeveloperRetransmissionDatabase =
      '/settings/developer/retransmission_database';
  static const String settingsDeveloperAutomatedTesting =
      '/settings/developer/automated_testing';
  static const String settingsInvite = '/settings/invite';
}
