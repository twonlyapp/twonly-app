import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/profile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_badge_info.comp.dart';
import 'package:twonly/src/visual/elements/svg_icon.element.dart';

class PrivacyView extends StatefulWidget {
  const PrivacyView({super.key});

  @override
  State<PrivacyView> createState() => _PrivacyViewState();
}

class _PrivacyViewState extends State<PrivacyView> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> toggleAuthRequirementOnStartup() async {
    final isAuth = await authenticateUser(
      userService.currentUser.screenLockEnabled
          ? context.lang.settingsScreenLockAuthMessageDisable
          : context.lang.settingsScreenLockAuthMessageEnable,
    );
    if (!isAuth) return;
    await UserService.update((u) {
      u.screenLockEnabled = !u.screenLockEnabled;
    });
    setState(() {});
  }

  Future<void> toggleTypingIndicators() async {
    await UserService.update((u) {
      u.typingIndicators = !u.typingIndicators;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsPrivacy),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.settingsPrivacyBlockUsers),
            subtitle: StreamBuilder(
              stream: twonlyDB.contactsDao.watchContactsBlocked(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    context.lang.settingsPrivacyBlockUsersCount(snapshot.data!),
                  );
                } else {
                  return Text(
                    context.lang.settingsPrivacyBlockUsersCount(0),
                  );
                }
              },
            ),
            onTap: () => context.push(Routes.settingsPrivacyBlockUsers),
          ),
          ListTile(
            title: Text(context.lang.contactVerifyNumberTitle),
            subtitle: Text(context.lang.contactVerifyNumberSubtitle),
            trailing: const _VerificationBadgeTriangle(),
            onTap: () async {
              await context.push(Routes.settingsHelpFaqVerifyBadge);
              setState(() {});
            },
          ),
          ListTile(
            title: Text(context.lang.userDiscoverySettingsTitle),
            onTap: () async {
              await context.push(Routes.settingsPrivacyUserDiscovery);
              setState(() {});
            },
          ),
          ListTile(
            title: Text(context.lang.settingsPrivacyProfileSelectionTitle),
            subtitle: Text(
              userService.currentUser.securityProfile == SecurityProfile.strict
                  ? context.lang.securityProfileStrictTitle
                  : context.lang.securityProfileNormalTitle,
            ),
            onTap: () async {
              await context.push(Routes.settingsPrivacyProfileSelection);
              setState(() {});
            },
          ),
          const Divider(),
          ListTile(
            title: Text(context.lang.settingsTypingIndication),
            subtitle: Text(context.lang.settingsTypingIndicationSubtitle),
            onTap: toggleTypingIndicators,
            trailing: Switch.adaptive(
              value: userService.currentUser.typingIndicators,
              onChanged: (a) => toggleTypingIndicators(),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(context.lang.settingsScreenLock),
            subtitle: Text(context.lang.settingsScreenLockSubtitle),
            onTap: toggleAuthRequirementOnStartup,
            trailing: Switch.adaptive(
              value: userService.currentUser.screenLockEnabled,
              onChanged: (a) => toggleAuthRequirementOnStartup(),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadgeTriangle extends StatelessWidget {
  const _VerificationBadgeTriangle();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 9,
            child: SvgIcon(
              assetPath: SvgIcons.verifiedGreen,
              size: 14,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: SvgIcon(
              assetPath: SvgIcons.verifiedGreen,
              size: 14,
              color: colorVerificationBadgeYellow,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: SvgIcon(
              assetPath: SvgIcons.verifiedRed,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
