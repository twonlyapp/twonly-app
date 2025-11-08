import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

class ContactVerifyQrScanView extends StatefulWidget {
  const ContactVerifyQrScanView(
    this.contact, {
    required this.fingerprint,
    super.key,
  });
  final Fingerprint fingerprint;
  final Contact contact;

  @override
  State<ContactVerifyQrScanView> createState() =>
      _ContactVerifyQrScanViewState();
}

class _ContactVerifyQrScanViewState extends State<ContactVerifyQrScanView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReaderWidget(
        onScan: (result) async {
          var isValid = false;
          try {
            if (result.text != null) {
              final otherFingerPrint = base64Decode(result.text!);
              isValid = widget.fingerprint.scannableFingerprint.compareTo(
                otherFingerPrint,
              );
            }
          } catch (e) {
            Log.error('$e');
          }
          return Navigator.pop(context, isValid);
        },
      ),
    );
  }
}
