import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/format_long_string.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/database/contacts_db.dart';
import 'package:twonly/src/database/database.dart';
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
    Stream<Contact?> contact = twonlyDatabase
        .getContactByUserId(widget.contact.userId)
        .watchSingleOrNull();

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
                StreamBuilder(
                  stream: contact,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == null) {
                      return Container();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        context.lang.contactVerifyNumberLongDesc(
                            getContactDisplayName(snapshot.data!)),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
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
              StreamBuilder(
                stream: contact,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Container();
                  }
                  final contact = snapshot.data!;
                  if (contact.verified) {
                    return OutlinedButton.icon(
                      onPressed: () {
                        final update =
                            ContactsCompanion(verified: Value(false));
                        twonlyDatabase.updateContact(contact.userId, update);
                      },
                      label: Text(
                          context.lang.contactVerifyNumberClearVerification),
                    );
                  }
                  return FilledButton.icon(
                    icon: FaIcon(FontAwesomeIcons.shieldHeart),
                    onPressed: () {
                      final update = ContactsCompanion(verified: Value(true));
                      twonlyDatabase.updateContact(contact.userId, update);
                    },
                    label: Text(context.lang.contactVerifyNumberMarkAsVerified),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
