import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/views/settings/subscription/voucher.view.dart';
import 'package:url_launcher/url_launcher.dart';

class RefundCreditsView extends StatefulWidget {
  const RefundCreditsView({super.key, required this.formattedBalance});
  final String formattedBalance;

  @override
  State<RefundCreditsView> createState() => _RefundCreditsViewState();
}

class _RefundCreditsViewState extends State<RefundCreditsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Credits'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Remaining balance: ${widget.formattedBalance}',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20), // Space between balance and options

            ListTile(
              title: Text("Create a Voucher"),
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return VoucherView();
                }));
                Navigator.pop(context, false);
              },
            ),
            ListTile(
              title: Text("Spend to an Open Source Project"),
              onTap: () async {},
            ),
            ListTile(
              title: Text("Spend to an NGO"),
              onTap: () async {},
            ),
            ListTile(
              title: Text("Spend to twonly"),
              onTap: () async {},
            ),
            Divider(),
            ListTile(
              title: Text(
                "Learn more about your donation",
              ),
              subtitle: Text(
                "This will open our webpage which will provide you more informations where we will donate your remaining ballance if you choose this option.",
              ),
              onTap: () {
                launchUrl(Uri.parse("https://twonly.eu/de/donation/"));
              },
              trailing: FaIcon(
                FontAwesomeIcons.arrowUpRightFromSquare,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
