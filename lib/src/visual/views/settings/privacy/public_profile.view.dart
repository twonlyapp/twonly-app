import 'package:flutter/material.dart';
import 'package:twonly/core/services/avatars.dart';
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/radio_button.element.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

class PublicProfilePrivacyView extends StatefulWidget {
  const PublicProfilePrivacyView({super.key});

  @override
  State<PublicProfilePrivacyView> createState() =>
      _PublicProfilePrivacyViewState();
}

class _PublicProfilePrivacyViewState extends State<PublicProfilePrivacyView> {
  CustomAvatarInfo? _customAvatar;
  bool _updatingAvatarVisibility = false;

  @override
  void initState() {
    super.initState();
    _loadCustomAvatarVisibility();
  }

  Future<void> _loadCustomAvatarVisibility() async {
    try {
      final avatar = await RustApi.getCustomAvatar();
      if (mounted) setState(() => _customAvatar = avatar);
    } on Object {
      // Keep the setting disabled when storage is unavailable. Other public
      // profile settings remain usable.
    }
  }

  Future<void> _setCustomAvatarVisibility(bool acceptedOnly) async {
    if (_updatingAvatarVisibility) return;
    setState(() => _updatingAvatarVisibility = true);
    try {
      final avatar = await RustApi.setCustomAvatarAudience(
        acceptedContactsOnly: acceptedOnly,
      );
      if (mounted) setState(() => _customAvatar = avatar);
    } finally {
      if (mounted) setState(() => _updatingAvatarVisibility = false);
    }
  }

  Future<void> _setTwonlyScoreVisibility(
    TwonlyScoreVisibility visibility,
  ) async {
    await UserService.update((user) {
      user.twonlyScoreVisibility = visibility;
    });
    if (mounted) setState(() {});
  }

  String _visibilityLabel(TwonlyScoreVisibility visibility) {
    return switch (visibility) {
      TwonlyScoreVisibility.nobody => context.lang.privacyVisibilityNobody,
      TwonlyScoreVisibility.onlyContacts =>
        context.lang.privacyVisibilityOnlyContacts,
      TwonlyScoreVisibility.everyone => context.lang.privacyVisibilityEveryone,
    };
  }

  String _avatarAudienceLabel(bool acceptedOnly) => acceptedOnly
      ? context.lang.customAvatarAcceptedOnly
      : context.lang.privacyVisibilityEveryone;

  /// Lets the user pick one of [options]; returns null when dismissed.
  Future<T?> _showChoiceDialog<T>({
    required String title,
    required T current,
    required List<T> options,
    required String Function(T) label,
    String? explanation,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (explanation != null) ...[
              Text(
                explanation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.color.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final option in options)
              RadioButton<T>(
                value: option,
                groupValue: current,
                label: label(option),
                onChanged: (value) => Navigator.of(context).pop(value),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTwonlyScoreVisibility() async {
    final selected = await _showChoiceDialog<TwonlyScoreVisibility>(
      title: context.lang.publicProfileTwonlyScore,
      current: userService.currentUser.twonlyScoreVisibility,
      options: TwonlyScoreVisibility.values,
      label: _visibilityLabel,
    );
    if (selected != null) await _setTwonlyScoreVisibility(selected);
  }

  Future<void> _selectCustomAvatarVisibility() async {
    final avatar = _customAvatar;
    if (avatar == null) return;
    final selected = await _showChoiceDialog<bool>(
      title: context.lang.customAvatarPhotoTab,
      current: avatar.acceptedContactsOnly,
      options: const [true, false],
      label: _avatarAudienceLabel,
      explanation: context.lang.customAvatarExplanation,
    );
    if (selected != null && selected != avatar.acceptedContactsOnly) {
      await _setCustomAvatarVisibility(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = TextStyle(color: context.color.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: Text(context.lang.publicProfilePrivacyTitle)),
      body: SettingsList(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.lang.publicProfilePrivacyDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.color.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            title: Text(context.lang.publicProfileTwonlyScore),
            subtitle: Text(
              _visibilityLabel(userService.currentUser.twonlyScoreVisibility),
              style: subtitleStyle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectTwonlyScoreVisibility,
          ),
          ListTile(
            enabled: _customAvatar != null && !_updatingAvatarVisibility,
            title: Text(context.lang.customAvatarPhotoTab),
            subtitle: Text(
              _avatarAudienceLabel(_customAvatar?.acceptedContactsOnly ?? true),
              style: subtitleStyle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectCustomAvatarVisibility,
          ),
        ],
      ),
    );
  }
}
