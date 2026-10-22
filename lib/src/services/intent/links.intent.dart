import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/key_verifications.dart'
    as rust_key_verifications;
import 'package:twonly/core/bridge/wrapper/signal.dart';
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/contact_enums.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/verification_failure_dialog.comp.dart';
import 'package:twonly/src/visual/components/verification_success_dialog.comp.dart';
import 'package:twonly/src/visual/views/contact/add_contact_via_qr_link.view.dart';
import 'package:twonly/src/visual/views/contact/add_new_contact.view.dart';

Future<bool> handleIntentUrl(BuildContext context, Uri uri) async {
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  if (uri.host != 'me.twonly.eu') return false;
  if (uri.hasEmptyPath) {
    if (context.mounted) await _showInvalidVerificationLink(context);
    return true;
  }

  // Check if this is the QR code link which was
  // therefore scanned with the system camera

  if (uri.toString().startsWith(PasswordlessRecoveryService.linkPrefix)) {
    await PasswordlessRecoveryService.handleRecoveryLink(uri.toString());
    return true;
  }

  if (uri.toString().startsWith(QrCodeUtils.linkPrefix)) {
    final result = await QrCodeUtils.handleQrCodeLink(uri.toString());

    if (!context.mounted) return false;

    switch (result.status) {
      case QrCodeLinkStatus.newContact:
        await context.navPush(
          AddContactViaQrLinkView(
            profile: result.profile!,
          ),
        );
      case QrCodeLinkStatus.verified:
        final contact = result.contact!;
        await VerificationSuccessDialog.show(context, contact);
        if (context.mounted) {
          await context.push(Routes.profileContact(contact.userId));
        }
      case QrCodeLinkStatus.ownProfile:
      case QrCodeLinkStatus.invalid:
      case QrCodeLinkStatus.keyMismatch:
      case QrCodeLinkStatus.missingSession:
      case QrCodeLinkStatus.error:
        await showQrCodeVerificationFailure(context, result);
    }

    return true;
  }

  final rawPathSegments = uri.pathSegments
      .where((part) => part.isNotEmpty)
      .toList();
  if (rawPathSegments.firstOrNull == 'qr' ||
      rawPathSegments.firstOrNull == 'r') {
    if (context.mounted) await _showInvalidVerificationLink(context);
    return true;
  }

  final publicKey = uri.hasFragment && uri.fragment.isNotEmpty
      ? uri.fragment
      : null;
  if (rawPathSegments.length != 1) {
    if (context.mounted) await _showInvalidVerificationLink(context);
    return true;
  }
  final username = rawPathSegments.single;

  if (!context.mounted) return false;

  if (username == userService.currentUser.username) {
    await context.push(Routes.settingsPublicProfile);
    return true;
  }

  Log.info(
    'Opened via deep link!: username = $username public_key = ${uri.fragment}',
  );

  Uint8List? receivedPublicKey;
  if (publicKey != null) {
    try {
      receivedPublicKey = base64Url.decode(publicKey);
    } catch (e) {
      Log.warn('Invalid public key in verification link: $e');
      await _showInvalidVerificationLink(context);
      return true;
    }
  }

  late final List<Contact> contacts;
  try {
    contacts = await rust_contacts.listContacts(
      input: db_contacts.ContactQuery(
        filter: db_contacts.ContactFilter.usernames,
        ids: Int64List(0),
        username: username,
        username2: '_______',
      ),
      transaction: currentDatabaseSession(),
    );
  } catch (e) {
    Log.warn('Could not load contact for verification link: $e');
    if (context.mounted) await _showVerificationLinkError(context);
    return true;
  }
  if (!context.mounted) return true;

  if (contacts.isEmpty) {
    // User does not yet exists, making a request...
    await context.navPush(
      AddNewUserView(
        username: username,
        publicKey: receivedPublicKey,
      ),
    );
    return true;
  }

  final contact = contacts.first;
  if (publicKey == null) {
    await VerificationFailureDialog.show(
      context,
      title: context.lang.couldNotVerifyUsername(
        getContactDisplayName(contact),
      ),
      message: context.lang.verificationLinkInvalid,
      contact: contact,
    );
    return true;
  }

  try {
    final storedPublicKey = await RustSignal.getContactPublicKey(
      contactId: contact.userId,
    );
    if (!context.mounted) return true;
    if (storedPublicKey == null) {
      await showQrCodeVerificationFailure(
        context,
        QrCodeLinkResult(
          status: QrCodeLinkStatus.missingSession,
          contact: contact,
        ),
      );
      return true;
    }
    if (receivedPublicKey == null || receivedPublicKey.isEmpty) {
      await showQrCodeVerificationFailure(
        context,
        QrCodeLinkResult(
          status: QrCodeLinkStatus.invalid,
          contact: contact,
        ),
      );
      return true;
    }
    if (storedPublicKey.equals(receivedPublicKey)) {
      final markAsVerified = await showAlertDialog(
        context,
        context.lang.linkFromUsername(contact.username),
        context.lang.linkFromUsernameLong,
        customOk: context.lang.gotLinkFromFriend,
      );
      if (markAsVerified) {
        await rust_key_verifications.changeKeyVerification(
          contact: contact.userId,
          kind: VerificationType.link.name,
          updateDiscovery: userService.currentUser.isUserDiscoveryEnabled,
          verifiedAt: clock.now().millisecondsSinceEpoch,
          callbackId: isolateCallbackId,
          transaction: currentDatabaseSession(),
        );
      }
      if (context.mounted) {
        await context.push(Routes.profileContact(contact.userId));
      }
    } else {
      await showQrCodeVerificationFailure(
        context,
        QrCodeLinkResult(
          status: QrCodeLinkStatus.keyMismatch,
          contact: contact,
        ),
      );
    }
  } catch (e) {
    Log.warn(e);
    if (context.mounted) {
      await showQrCodeVerificationFailure(
        context,
        QrCodeLinkResult(
          status: QrCodeLinkStatus.error,
          contact: contact,
        ),
      );
    }
  }

  return true;
}

Future<void> _showInvalidVerificationLink(BuildContext context) {
  return VerificationFailureDialog.show(
    context,
    title: context.lang.verificationLinkInvalidTitle,
    message: context.lang.verificationLinkInvalid,
  );
}

Future<void> _showVerificationLinkError(BuildContext context) {
  return VerificationFailureDialog.show(
    context,
    title: context.lang.verificationLinkErrorTitle,
    message: context.lang.verificationLinkError,
  );
}

StreamSubscription<List<SharedFile>> initIntentStreams(
  BuildContext context,
  Future<void> Function(Uri) onUrlCallBack,
  void Function(String, MediaType) onMediaCallBack,
) {
  FlutterSharingIntent.instance.getInitialSharing().then((f) async {
    if (!context.mounted) return;
    await handleIntentSharedFile(context, f, onUrlCallBack, onMediaCallBack);
  });

  return FlutterSharingIntent.instance.getMediaStream().listen(
    (f) async {
      if (!context.mounted) return;
      await handleIntentSharedFile(context, f, onUrlCallBack, onMediaCallBack);
    },
    // ignore: inference_failure_on_untyped_parameter
    onError: (err) {
      Log.error('getIntentDataStream error: $err');
    },
  );
}

Future<void> handleIntentSharedFile(
  BuildContext context,
  List<SharedFile> files,
  Future<void> Function(Uri) onUrlCallBack,
  void Function(String, MediaType) onMediaCallBack,
) async {
  for (final file in files) {
    final value = file.value;
    if (value == null || value.trim().isEmpty) {
      Log.warn(
        'Ignoring shared item with an empty value: ${file.type}, ${file.mimeType}',
      );
      continue;
    }

    Log.info('got file via intent ${file.type}');

    switch (file.type) {
      case SharedMediaType.URL:
        if (value.startsWith('http')) {
          final uri = Uri.parse(value);
          Log.info('Got link via handle intent share file: ${uri.scheme}');
          await onUrlCallBack(uri);
        }
      case SharedMediaType.IMAGE:
        var type = MediaType.image;
        if (value.endsWith('.gif')) {
          type = MediaType.gif;
        }
        onMediaCallBack(value, type);
      case SharedMediaType.VIDEO:
        onMediaCallBack(value, MediaType.video);
      // ignore: no_default_cases
      default:
    }
    break; // only handle one file...
  }
}
