import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/help/changelog.view.dart';
import 'package:twonly/src/views/settings/help/contact_us.view.dart';
import 'package:twonly/src/views/settings/help/credits.view.dart';
import 'package:twonly/src/views/settings/help/diagnostics.view.dart';
import 'package:twonly/src/views/settings/help/faq.view.dart';
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const FaqView();
                  },
                ),
              );
            },
          ),
          ListTile(
            title: Text(context.lang.settingsHelpContactUs),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const ContactUsView();
                  },
                ),
              );
            },
          ),
          // ListTile(
          //   title: Text(context.lang.settingsResetTutorials),
          //   subtitle: Text(
          //     context.lang.settingsResetTutorialsDesc,
          //     style: const TextStyle(fontSize: 12),
          //   ),
          //   onTap: () async {
          //     await updateUserdata((user) {
          //       user.tutorialDisplayed = [];
          //       return user;
          //     });
          //     if (!context.mounted) return;
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         content: Text(context.lang.settingsResetTutorialsSuccess),
          //         duration: const Duration(seconds: 3),
          //       ),
          //     );
          //   },
          // ),
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const DiagnosticsView();
                  },
                ),
              );
            },
          ),
          const Divider(),
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
            onTap: () {
              showLicensePage(context: context);
            },
          ),
          ListTile(
            title: Text(context.lang.settingsHelpCredits),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const CreditsView();
                  },
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Changelog'),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const ChangeLogView();
                  },
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Open Source'),
            onTap: () async {
              await launchUrl(
                Uri.parse('https://github.com/twonlyapp/twonly-app'),
              );
            },
            trailing:
                const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
          ),
          ListTile(
            title: Text(context.lang.settingsHelpImprint),
            onTap: () async {
              await launchUrl(Uri.parse('https://twonly.eu/de/legal/'));
            },
            trailing:
                const FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
          ),
          ListTile(
            title: Text(context.lang.settingsHelpTerms),
            onTap: () async {
              await launchUrl(Uri.parse('https://twonly.eu/de/legal/agb.html'));
            },
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
