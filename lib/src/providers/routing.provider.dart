import 'package:go_router/go_router.dart';
import 'package:twonly/app.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/views/camera/camera_qr_scanner.view.dart';
import 'package:twonly/src/views/camera/camera_send_to.view.dart';
import 'package:twonly/src/views/chats/add_new_user.view.dart';
import 'package:twonly/src/views/chats/archived_chats.view.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/chats/media_viewer.view.dart';
import 'package:twonly/src/views/chats/start_new_chat.view.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/groups/group.view.dart';
import 'package:twonly/src/views/groups/group_create_select_members.view.dart';
import 'package:twonly/src/views/onboarding/recover.view.dart';
import 'package:twonly/src/views/public_profile.view.dart';
import 'package:twonly/src/views/settings/account.view.dart';
import 'package:twonly/src/views/settings/appearance.view.dart';
import 'package:twonly/src/views/settings/backup/backup.view.dart';
import 'package:twonly/src/views/settings/backup/backup_server.view.dart';
import 'package:twonly/src/views/settings/backup/setup_backup.view.dart';
import 'package:twonly/src/views/settings/chat/chat_reactions.view.dart';
import 'package:twonly/src/views/settings/chat/chat_settings.view.dart';
import 'package:twonly/src/views/settings/data_and_storage.view.dart';
import 'package:twonly/src/views/settings/data_and_storage/export_media.view.dart';
import 'package:twonly/src/views/settings/data_and_storage/import_media.view.dart';
import 'package:twonly/src/views/settings/developer/automated_testing.view.dart';
import 'package:twonly/src/views/settings/developer/developer.view.dart';
import 'package:twonly/src/views/settings/developer/retransmission_data.view.dart';
import 'package:twonly/src/views/settings/help/changelog.view.dart';
import 'package:twonly/src/views/settings/help/contact_us.view.dart';
import 'package:twonly/src/views/settings/help/credits.view.dart';
import 'package:twonly/src/views/settings/help/diagnostics.view.dart';
import 'package:twonly/src/views/settings/help/faq.view.dart';
import 'package:twonly/src/views/settings/help/help.view.dart';
import 'package:twonly/src/views/settings/notification.view.dart';
import 'package:twonly/src/views/settings/privacy.view.dart';
import 'package:twonly/src/views/settings/privacy_view_block.view.dart';
import 'package:twonly/src/views/settings/profile/modify_avatar.view.dart';
import 'package:twonly/src/views/settings/profile/profile.view.dart';
import 'package:twonly/src/views/settings/settings_main.view.dart';
import 'package:twonly/src/views/settings/share_with_friends.view.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';
import 'package:twonly/src/views/user_study/user_study_questionnaire.view.dart';
import 'package:twonly/src/views/user_study/user_study_welcome.view.dart';

final routerProvider = GoRouter(
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const AppMainWidget(initialPage: 1),
    ),

    // Chats
    GoRoute(
      path: Routes.chats,
      builder: (context, state) => const AppMainWidget(initialPage: 0),
      routes: [
        GoRoute(
          path: 'add_new_user',
          builder: (context, state) => const AddNewUserView(),
        ),
        GoRoute(
          path: 'archived',
          builder: (context, state) => const ArchivedChatsView(),
        ),
        GoRoute(
          path: 'start_new_chat',
          builder: (context, state) => const StartNewChatView(),
        ),
        GoRoute(
          path: 'camera_send_to',
          builder: (context, state) {
            final group = state.extra! as Group;
            return CameraSendToView(group);
          },
        ),
        GoRoute(
          path: 'media_viewer',
          builder: (context, state) {
            final group = state.extra! as Group;
            return MediaViewerView(group);
          },
        ),
        GoRoute(
          path: 'messages',
          builder: (context, state) {
            final group = state.extra! as Group;
            return ChatMessagesView(group);
          },
        ),
      ],
    ),

    GoRoute(
      path: '/profile/contact/:contactId',
      builder: (context, state) {
        final contactId = state.pathParameters['contactId']!;
        return ContactView(int.parse(contactId));
      },
    ),

    GoRoute(
      path: '/profile/group/:groupId',
      builder: (context, state) {
        final groupId = state.pathParameters['groupId']!;
        return GroupView(groupId);
      },
    ),

    GoRoute(
      path: '/group/create/select_member',
      builder: (context, state) {
        return const GroupCreateSelectMembersView();
      },
      routes: [
        GoRoute(
          path: ':groupId',
          builder: (context, state) {
            final groupId = state.pathParameters['groupId'];
            return GroupCreateSelectMembersView(groupId: groupId);
          },
        ),
      ],
    ),

    GoRoute(
      path: Routes.cameraQRScanner,
      builder: (context, state) {
        return const QrCodeScannerView();
      },
    ),

    // settings
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsMainView(),
      routes: [
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileView(),
          routes: [
            GoRoute(
              path: 'modify_avatar',
              builder: (context, state) => const ModifyAvatarView(),
            )
          ],
        ),
        GoRoute(
          path: 'public_profile',
          builder: (context, state) => const PublicProfileView(),
        ),
        GoRoute(
          path: 'account',
          builder: (context, state) => const AccountView(),
        ),
        GoRoute(
          path: 'subscription',
          builder: (context, state) => const SubscriptionView(),
        ),
        GoRoute(
          path: 'backup',
          builder: (context, state) => const BackupView(),
          routes: [
            GoRoute(
              path: 'server',
              builder: (context, state) => const BackupServerView(),
            ),
            GoRoute(
              path: 'recovery',
              builder: (context, state) => const BackupRecoveryView(),
            ),
            GoRoute(
              path: 'setup',
              builder: (context, state) => SetupBackupView(
                isPasswordChangeOnly: state.extra as bool? ?? false,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'appearance',
          builder: (context, state) => const AppearanceView(),
        ),
        GoRoute(
          path: 'chats',
          builder: (context, state) => const ChatSettingsView(),
          routes: [
            GoRoute(
              path: 'reactions',
              builder: (context, state) => const ChatReactionSelectionView(),
            ),
          ],
        ),
        GoRoute(
          path: 'privacy',
          builder: (context, state) => const PrivacyView(),
          routes: [
            GoRoute(
              path: 'block_users',
              builder: (context, state) => const PrivacyViewBlockUsersView(),
            )
          ],
        ),
        GoRoute(
          path: 'notification',
          builder: (context, state) => const NotificationView(),
        ),
        GoRoute(
          path: 'storage_data',
          builder: (context, state) => const DataAndStorageView(),
          routes: [
            GoRoute(
              path: 'import',
              builder: (context, state) => const ImportMediaView(),
            ),
            GoRoute(
              path: 'export',
              builder: (context, state) => const ExportMediaView(),
            ),
          ],
        ),
        GoRoute(
          path: 'help',
          builder: (context, state) => const HelpView(),
          routes: [
            GoRoute(
              path: 'faq',
              builder: (context, state) => const FaqView(),
            ),
            GoRoute(
              path: 'contact_us',
              builder: (context, state) => const ContactUsView(),
            ),
            GoRoute(
              path: 'diagnostics',
              builder: (context, state) => const DiagnosticsView(),
            ),
            GoRoute(
              path: 'user_study',
              builder: (context, state) => UserStudyWelcomeView(
                wasOpenedAutomatic: state.extra as bool? ?? false,
              ),
              routes: [
                GoRoute(
                  path: 'questionnaire',
                  builder: (context, state) =>
                      const UserStudyQuestionnaireView(),
                ),
              ],
            ),
            GoRoute(
              path: 'credits',
              builder: (context, state) => const CreditsView(),
            ),
            GoRoute(
              path: 'changelog',
              builder: (context, state) => ChangeLogView(
                changeLog: state.extra as String?,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'developer',
          builder: (context, state) => const DeveloperSettingsView(),
          routes: [
            GoRoute(
              path: 'retransmission_database',
              builder: (context, state) => const RetransmissionDataView(),
            ),
            GoRoute(
              path: 'automated_testing',
              builder: (context, state) => const AutomatedTestingView(),
            ),
          ],
        ),
        GoRoute(
          path: 'invite',
          builder: (context, state) => const ShareWithFriendsView(),
        ),
      ],
    ),
  ],
);
