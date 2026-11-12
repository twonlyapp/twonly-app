import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:twonly/core/bridge/memory_importer.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/views/settings/backup/connect_importer.view.dart';

/// The app's side of the memories importer: where pairing links may lead,
/// how claim errors read, and when to look for imported memories.
class MemoryImporterService {
  /// Where users open the importer page; named on the connect screen.
  static const importerOrigin = 'import.twonly.eu';

  static bool isPairingLink(String link) {
    try {
      return RustMemoryImporter.isPairingLink(link: link);
    } catch (_) {
      return false;
    }
  }

  /// A pairing link scanned with the twonly camera, the only way in: shows
  /// the connect screen. Nothing is claimed there without the user's
  /// confirmation.
  static Future<void> openFromScanner(BuildContext context, String link) async {
    if (!context.mounted) return;
    await context.navPush(ConnectImporterView(link: link));
  }

  /// A pairing link from anywhere else (the system camera, a universal link
  /// tapped in another app, a chat message, shared text): never leads to the
  /// connect screen. The OS cannot tell a camera scan from a link someone
  /// sent, and someone who sends a code wants access.
  static Future<void> refuseLink(BuildContext context) async {
    if (!context.mounted) return;
    await showAlertDialog(
      context,
      context.lang.memoryImporterScanOnlyTitle,
      context.lang.memoryImporterScanOnly,
      customCancel: '',
    );
  }

  static int? _apiErrorCode(Object error) {
    final message = error is AnyhowException ? error.message : error.toString();
    final match = RegExp(r'API error code (\d+)').firstMatch(message);
    return match == null ? null : int.parse(match.group(1)!);
  }

  static String claimErrorText(BuildContext context, Object error) {
    return switch (_apiErrorCode(error)) {
      1040 => context.lang.memoryImporterAlreadyClaimed,
      1041 => context.lang.memoryImporterCodeExpired,
      1042 => context.lang.memoryImporterTooMany,
      1022 => context.lang.memoryImporterNeedsPlan,
      _ => context.lang.memoryImporterConnectFailed,
    };
  }

  /// Looks for imported memories this device does not have yet. Cheap when
  /// nothing changed: the Rust side compares counts before it lists.
  static Future<void> reconcile({bool force = false}) async {
    try {
      await RustMemoryImporter.reconcile(force: force);
    } catch (error) {
      Log.warn('imported memories reconciliation: $error');
    }
  }

  /// After a pairing, the first uploads arrive within seconds; the server's
  /// push triggers the scans after that.
  static Future<void> reconcileSoon() async {
    await Future<void>.delayed(const Duration(seconds: 30));
    await reconcile(force: true);
  }
}
