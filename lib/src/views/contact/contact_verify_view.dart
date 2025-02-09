import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:twonly/src/components/format_long_string.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/signal.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactVerifyView extends StatefulWidget {
  const ContactVerifyView(this.contact, {super.key});

  final Contact contact;

  @override
  State<ContactVerifyView> createState() => _ContactVerifyViewState();
}

class _ContactVerifyViewState extends State<ContactVerifyView> {
  Fingerprint? fingerprint;

  @override
  void initState() {
    super.initState();
    loadAsync();
  }

  Future loadAsync() async {
    fingerprint = await generateSessionFingerPrint(widget.contact.userId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Contact contact = context
        .watch<ContactChangeProvider>()
        .allContacts
        .firstWhere((c) => c.userId == widget.contact.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.contactVerifyNumberTitle),
      ),
      body: (fingerprint == null)
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            child: QrImageView(
                              data: base64Encode(fingerprint!
                                  .scannableFingerprint.fingerprints),
                              version: QrVersions.auto,
                              size: 150.0,
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            width: 200,
                            child: Text(
                              "QR Code scanning is coming soon. Please compare the numbers manual.",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 20),
                          FormattedStringWidget(
                            fingerprint!.displayableFingerprint
                                .getDisplayText(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    context.lang
                        .contactVerifyNumberLongDesc(contact.displayName),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse("https://twonly.eu/verify"));
                    },
                    child: Text(
                      "Read more.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                )
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              contact.verified
                  ? OutlinedButton.icon(
                      onPressed: () {
                        DbContacts.updateVerificationStatus(
                            contact.userId.toInt(), false);
                      },
                      label: Text(
                          context.lang.contactVerifyNumberClearVerification),
                    )
                  : FilledButton.icon(
                      icon: FaIcon(FontAwesomeIcons.shieldHeart),
                      onPressed: () {
                        DbContacts.updateVerificationStatus(
                            contact.userId.toInt(), true);
                      },
                      label:
                          Text(context.lang.contactVerifyNumberMarkAsVerified),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
