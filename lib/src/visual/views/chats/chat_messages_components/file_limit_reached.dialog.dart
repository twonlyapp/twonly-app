import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/core/services/media_upload.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';

/// Explains a send that stopped because the media exceeded the largest single
/// object the user's plan accepts.
///
/// Only the free plan is offered an upgrade: every paid plan shares the same
/// per-file limit, so changing plan would not make this file sendable.
Future<void> showFileLimitReachedDialog(
  BuildContext context,
  String mediaId,
) async {
  MediaSizeReport? report;
  try {
    report = await RustApi.mediaSizeLimitReport(mediaId: mediaId);
  } catch (_) {
    // The numbers are what make the warning specific, but the warning is
    // still worth showing without them.
  }
  if (!context.mounted) return;

  final isFreePlan =
      context.read<PurchasesProvider>().plan == SubscriptionPlan.Free;
  final limit = report?.limitBytes;
  final size = report?.mediaBytes;

  String? detail;
  if (limit != null) {
    detail = size != null
        ? context.lang.fileLimitReachedDetail(
            formatBytes(size),
            formatBytes(limit),
          )
        : context.lang.fileLimitReachedDetailNoSize(formatBytes(limit));
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.lang.fileLimitReachedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail != null) ...[
            Text(detail),
            const SizedBox(height: 12),
          ],
          Text(
            isFreePlan
                ? dialogContext.lang.fileLimitReachedHintFree
                : dialogContext.lang.fileLimitReachedHint,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.lang.close),
        ),
        if (isFreePlan)
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              dialogContext.push(Routes.settingsSubscription);
            },
            child: Text(dialogContext.lang.fileLimitReachedUpgrade),
          ),
      ],
    ),
  );
}
