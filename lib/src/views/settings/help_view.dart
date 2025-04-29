import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/credits_view.dart';
import 'package:twonly/src/views/settings/diagnostics_view.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(context.lang.settingsHelp),
        ),
        body: ListView(
          children: [
            ListTile(
              title: Text(context.lang.settingsHelpSupport),
              onTap: () {
                launchUrl(Uri.parse("https://twonly.eu/support"));
              },
              trailing:
                  FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
            ),
            Divider(),
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
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return CreditsView();
                }));
              },
            ),
            ListTile(
              title: Text(context.lang.settingsHelpDiagnostics),
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return DiagnosticsView();
                }));
              },
            ),
            ListTile(
              title: Text(context.lang.settingsHelpLegal),
              onTap: () {
                launchUrl(Uri.parse("https://twonly.eu/legal"));
              },
              trailing:
                  FaIcon(FontAwesomeIcons.arrowUpRightFromSquare, size: 15),
            ),
            ListTile(
              title: Text(
                "Copyright twonly",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ));
  }
}
