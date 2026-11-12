import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

@immutable
class ReleaseNoteFeature {
  const ReleaseNoteFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final Widget icon;
  final String title;
  final String description;
}

@immutable
class ReleaseNotesData {
  const ReleaseNotesData({
    required this.version,
    required this.title,
    required this.introduction,
    required this.additionalChangesTitle,
    required this.closeLabel,
    required this.features,
    required this.additionalChanges,
  });

  final String version;
  final String title;
  final String introduction;
  final String additionalChangesTitle;
  final String closeLabel;
  final List<ReleaseNoteFeature> features;
  final List<String> additionalChanges;
}

/// A sheet that announces what is new and is shown once per account.
@immutable
class ReleaseNotice {
  const ReleaseNotice({required this.version, required this.show});

  /// Stored in `lastReleaseNotesVersion` once the notice was shown.
  final String version;
  final Future<void> Function(BuildContext context) show;
}

/// Coordinates the once-per-version behavior for release notes and feature
/// notices: the oldest unseen notice is shown, at most one per app start.
class ReleaseNotesPresenter {
  ReleaseNotesPresenter._();

  static bool _showing = false;
  static bool _shownThisSession = false;

  static bool isSeen(String version) {
    final last = userService.currentUser.lastReleaseNotesVersion;
    return last != null && compareVersions(last, version) >= 0;
  }

  /// Returns whether a notice is on screen or was just shown.
  static Future<bool> showIfNeeded(
    BuildContext context,
    List<ReleaseNotice> notices,
  ) async {
    if (_showing) return true;
    if (_shownThisSession) return false;
    final notice = notices.where((n) => !isSeen(n.version)).firstOrNull;
    if (notice == null) return false;

    _showing = true;
    try {
      await notice.show(context);
      _shownThisSession = true;
      await UserService.update(
        (user) => user.lastReleaseNotesVersion = notice.version,
      );
    } finally {
      _showing = false;
    }
    return true;
  }
}

/// Compares dotted version numbers like `0.6.0` and `0.7.1` numerically.
int compareVersions(String a, String b) {
  List<int> parts(String v) =>
      v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final diff = (i < pa.length ? pa[i] : 0) - (i < pb.length ? pb[i] : 0);
    if (diff != 0) return diff;
  }
  return 0;
}

Future<void> showReleaseNotesBottomSheet(
  BuildContext context,
  ReleaseNotesData releaseNotes,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.8,
      child: ReleaseNotesBottomSheet(releaseNotes: releaseNotes),
    ),
  );
}

class ReleaseNotesBottomSheet extends StatelessWidget {
  const ReleaseNotesBottomSheet({
    required this.releaseNotes,
    super.key,
  });

  final ReleaseNotesData releaseNotes;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.color.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const _DragHandle(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _Header(releaseNotes: releaseNotes),
                  const SizedBox(height: 24),
                  ...releaseNotes.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FeatureCard(feature: feature),
                    ),
                  ),
                  if (releaseNotes.additionalChanges.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      releaseNotes.additionalChangesTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.color.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...releaseNotes.additionalChanges.map(
                      (change) => _AdditionalChange(text: change),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: MyButton(
                onPressed: () => Navigator.pop(context),
                child: Text(releaseNotes.closeLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.color.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.releaseNotes});

  final ReleaseNotesData releaseNotes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.color.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              'v${releaseNotes.version}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.color.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          releaseNotes.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          releaseNotes.introduction,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.color.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final ReleaseNoteFeature feature;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.color.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(
                  size: 20,
                  color: context.color.onPrimaryContainer,
                ),
                child: feature.icon,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    feature.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.color.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdditionalChange extends StatelessWidget {
  const _AdditionalChange({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.color.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 15,
              color: context.color.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
