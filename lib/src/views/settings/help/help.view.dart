import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpView extends StatefulWidget {
  const HelpView({super.key});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  Future<void> toggleAllowErrorTrackingViaSentry() async {
    await updateUserdata((u) {
      u.allowErrorTrackingViaSentry = !u.allowErrorTrackingViaSentry;
      return u;
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsHelp),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.settingsHelpFAQ),
            onTap: () => context.push(Routes.settingsHelpFaq),
          ),
          ListTile(
            title: Text(context.lang.settingsHelpContactUs),
            onTap: () => context.push(Routes.settingsHelpContactUs),
          ),
          const Divider(),
          ListTile(
            title: Text(context.lang.allowErrorTracking),
            subtitle: Text(
              context.lang.allowErrorTrackingSubtitle,
              style: const TextStyle(fontSize: 10),
            ),
            onTap: toggleAllowErrorTrackingViaSentry,
            trailing: Switch(
              value: gUser.allowErrorTrackingViaSentry,
              onChanged: (a) => toggleAllowErrorTrackingViaSentry(),
            ),
          ),
          ListTile(
            title: Text(context.lang.settingsHelpDiagnostics),
            onTap: () => context.push(Routes.settingsHelpDiagnostics),
          ),
          const Divider(),
          if (gUser.userStudyParticipantsToken == null || kDebugMode)
            ListTile(
              title: const Text('Teilnahme an Nutzerstudie'),
              onTap: () => context.push(Routes.settingsHelpUserStudy),
            ),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) {
              if (snap.hasData) {
                return ListTile(
                  title: Text(context.lang.settingsHelpVersion),
                  subtitle: Text(snap.data!.version),
                );
              } else {
                return Container();
              }
            },
          ),
          ListTile(
            title: Text(context.lang.settingsHelpLicenses),
            onTap: () => showLicensePage(context: context),
          ),
          ListTile(
            title: Text(context.lang.settingsHelpCredits),
            onTap: () => context.push(Routes.settingsHelpCredits),
          ),
          ListTile(
            title: const Text('Changelog'),
            onTap: () => context.push(Routes.settingsHelpChangelog),
          ),
          ListTile(
            title: const Text('Open Source'),
            onTap: () => launchUrl(
              Uri.parse('https://github.com/twonlyapp/twonly-app'),
            ),
            trailing:
                const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
          ),
          ListTile(
            title: Text(context.lang.settingsHelpImprint),
            onTap: () => launchUrl(Uri.parse('https://twonly.eu/de/legal/')),
            trailing:
                const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
          ),
          ListTile(
            title: Text(context.lang.settingsHelpTerms),
            onTap: () =>
                launchUrl(Uri.parse('https://twonly.eu/de/legal/agb.html')),
            trailing:
                const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
          ),
          ListTile(
            onLongPress: () async {
              final okay = await showAlertDialog(
                context,
                'Developer Settings',
                'Do you want to enable the developer settings?',
              );
              if (okay) {
                await updateUserdata((u) {
                  u.isDeveloper = true;
                  return u;
                });
              }
            },
            title: const Text(
              'Copyright twonly',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
