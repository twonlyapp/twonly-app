import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/core/bridge/memory_importer.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

/// Shows a bar at the top of the app while memories that an importer page
/// uploaded are added to this device.
///
/// Once the server announces imported memories, Rust downloads, checks and
/// decrypts each thumbnail before it appears in the gallery. With thousands of
/// memories that takes a while, so the bar shows how far it has got. It pushes
/// [child] down instead of covering it, so no app bar is hidden, and it never
/// blocks the app.
class MemoryImportProgressBar extends StatefulWidget {
  const MemoryImportProgressBar({required this.child, super.key});

  final Widget? child;

  @override
  State<MemoryImportProgressBar> createState() =>
      _MemoryImportProgressBarState();
}

class _MemoryImportProgressBarState extends State<MemoryImportProgressBar> {
  StreamSubscription<MemoryImportProgress>? _subscription;
  MemoryImportProgress? _progress;

  @override
  void initState() {
    super.initState();
    // The stream starts with the current state, so a bar mounted halfway
    // through an import shows it straight away.
    _subscription = RustMemoryImporter.progress().listen(
      (progress) {
        if (mounted) setState(() => _progress = progress);
      },
      onError: (Object error, StackTrace stackTrace) {
        Log.error(
          'Memory import progress stream failed',
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
    final active = progress != null && progress.active && progress.total > 0;

    // The tree keeps its shape whether the bar shows or not, so the navigator
    // below is never rebuilt from scratch.
    //
    // Nothing else paints behind the navigator. Page transitions such as the
    // back gesture round a page's corners, which would show black right below
    // the bar, so the bar's color fills in behind the pages while it shows.
    return ColoredBox(
      color: active ? context.color.surfaceContainerHigh : Colors.transparent,
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: active
                ? _Banner(progress: progress)
                : const SizedBox(width: double.infinity),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: active,
              child: widget.child ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.progress});

  final MemoryImportProgress progress;

  @override
  Widget build(BuildContext context) {
    final total = progress.total;
    final done = progress.done.clamp(0, total);
    final value = progress.waiting || total <= 0 ? 1.0 : done / total;
    // Between an import page's batches the bar shows what was added so far.
    final count = progress.waiting
        ? context.lang.memoryImportProgressAdded(done)
        : context.lang.memoryImportProgressCount(done, total);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: context.color.surfaceContainerHigh,
        child: SafeArea(
          bottom: false,
          child: Semantics(
            liveRegion: true,
            label: context.lang.memoryImportProgressTitle,
            value: count,
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                          color: context.color.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.lang.memoryImportProgressTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          count,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.color.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: value),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
