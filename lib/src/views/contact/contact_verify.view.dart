import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:lottie/lottie.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/views/components/format_long_string.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact_verify_qr_scan.view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as imglib;

class ContactVerifyView extends StatefulWidget {
  const ContactVerifyView(this.contact, {super.key});
  final Contact contact;

  @override
  State<ContactVerifyView> createState() => _ContactVerifyViewState();
}

enum ScanResult { None, Success, Failed }

class _ContactVerifyViewState extends State<ContactVerifyView> {
  Fingerprint? _fingerprint;
  late Contact _contact;
  late StreamSubscription<Contact?> _contactSub;
  ScanResult _scanResult = ScanResult.None;
  Uint8List? _qrCodeImageBytes;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    loadAsync();
  }

  @override
  void dispose() {
    _contactSub.cancel();
    super.dispose();
  }

  Future loadAsync() async {
    _fingerprint = await generateSessionFingerPrint(widget.contact.userId);

    if (_fingerprint != null) {
      final Encode result = zx.encodeBarcode(
        contents: base64Encode(
          _fingerprint!.scannableFingerprint.fingerprints,
        ),
        params: EncodeParams(
          format: Format.qrCode,
          width: 150,
          height: 150,
          margin: 0,
          eccLevel: EccLevel.low,
        ),
      );
      if (result.isValid && result.data != null) {
        final img = imglib.Image.fromBytes(
          width: 150,
          height: 150,
          bytes: result.data!.buffer,
          numChannels: 1,
        );
        _qrCodeImageBytes = imglib.encodePng(img);
      }
    }

    Stream<Contact?> contact = twonlyDB.contactsDao
        .getContactByUserId(widget.contact.userId)
        .watchSingleOrNull();
    _contactSub = contact.listen((contact) {
      if (contact == null) return;
      setState(() {
        _contact = contact;
      });
    });
    setState(() {});
  }

  Future openQrScanner() async {
    if (_fingerprint == null) return;
    bool? isValid = await Navigator.push(context, MaterialPageRoute(
      builder: (context) {
        return ContactVerifyQrScanView(
          widget.contact,
          fingerprint: _fingerprint!,
        );
      },
    ));
    if (isValid == null) {
      return; // user just returned...
    }
    if (isValid) {
      _scanResult = ScanResult.Success;
      updateUserVerifyState(true);
    } else {
      _scanResult = ScanResult.Failed;
      updateUserVerifyState(false);
    }
    setState(() {});
  }

  Future updateUserVerifyState(bool verified) async {
    final update = ContactsCompanion(verified: Value(verified));
    await twonlyDB.contactsDao.updateContact(_contact.userId, update);
  }

  Widget get qrWidget => (_qrCodeImageBytes == null)
      ? SizedBox(
          width: 150,
          height: 150,
        )
      : Image.memory(_qrCodeImageBytes!);
  Widget get resultAnimation => SizedBox(
        width: 150,
        child: Lottie.asset(
          (_scanResult == ScanResult.Success)
              ? 'assets/animations/success.json'
              : 'assets/animations/failed.json',
          repeat: false,
          onLoaded: (p0) {
            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _scanResult = ScanResult.None;
                });
              }
            });
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.contactVerifyNumberTitle),
      ),
      body: (_fingerprint == null)
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
                      child: GestureDetector(
                        onTap: openQrScanner,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  (_scanResult == ScanResult.None)
                                      ? qrWidget
                                      : resultAnimation,
                                  SizedBox(height: 10),
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      (_scanResult == ScanResult.None)
                                          ? context
                                              .lang.contactVerifyNumberTapToScan
                                          : "",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            FormattedStringWidget(
                              _fingerprint!.displayableFingerprint
                                  .getDisplayText(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    context.lang.contactVerifyNumberLongDesc(
                        getContactDisplayName(_contact)),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse(
                          "https://twonly.eu/en/faq/security/verify-security-number.html"));
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
              (_contact.verified)
                  ? OutlinedButton.icon(
                      onPressed: () => updateUserVerifyState(false),
                      label: Text(
                          context.lang.contactVerifyNumberClearVerification),
                    )
                  : FilledButton.icon(
                      icon: FaIcon(FontAwesomeIcons.shieldHeart),
                      onPressed: () => updateUserVerifyState(true),
                      label: Text(
                        context.lang.contactVerifyNumberMarkAsVerified,
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
