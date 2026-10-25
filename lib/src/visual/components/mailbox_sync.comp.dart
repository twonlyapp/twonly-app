import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/api.dart' as rust_api;
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

/// Blocks the app while a large mailbox is caught up.
///
/// Rust starts a catch-up once the server reports more than 2000 waiting
/// messages and ends it when the mailbox is drained. Until then new messages
/// queue behind the old ones, so the app shows how far it has got instead of
/// looking as if nothing arrives. The overlay cannot be dismissed; Rust ends it
/// by itself once a catch-up stops making progress.
class MailboxSyncOverlay extends StatefulWidget {
  const MailboxSyncOverlay({super.key});

  @override
  State<MailboxSyncOverlay> createState() => _MailboxSyncOverlayState();
}

class _MailboxSyncOverlayState extends State<MailboxSyncOverlay> {
  StreamSubscription<rust_api.MailboxSyncProgress>? _subscription;
  rust_api.MailboxSyncProgress? _progress;

  @override
  void initState() {
    super.initState();
    // The stream starts with the current state, so an overlay mounted halfway
    // through a catch-up shows it straight away.
    _subscription = rust_api.RustApi.mailboxSyncProgress().listen(
      (progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onError: (Object error, StackTrace stackTrace) {
        Log.error(
          'Mailbox sync progress stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null || !progress.active) {
      return const SizedBox.shrink();
    }

    final total = progress.total;
    final remaining = progress.remaining;
    final done = total <= 0
        ? 0.0
        : ((total - remaining) / total).clamp(0.0, 1.0);

    return Positioned.fill(
      child: Stack(
        children: [
          const ModalBarrier(dismissible: false, color: Colors.black54),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Material(
                    color: context.color.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 40,
                            color: context.color.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.lang.mailboxSyncTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.lang.mailboxSyncBody,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: done),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                    value: value,
                                    minHeight: 8,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.lang.mailboxSyncRemaining(remaining),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.color.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
