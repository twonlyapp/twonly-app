import 'package:flutter/material.dart';
import 'package:twonly/core/services/avatars.dart';
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.lang.publicProfilePrivacyTitle)),
      body: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              context.lang.publicProfilePrivacyDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.color.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(context.lang.publicProfileTwonlyScore),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<TwonlyScoreVisibility>(
                value: userService.currentUser.twonlyScoreVisibility,
                items: TwonlyScoreVisibility.values
                    .map(
                      (visibility) => DropdownMenuItem(
                        value: visibility,
                        child: Text(_visibilityLabel(visibility)),
                      ),
                    )
                    .toList(),
                onChanged: (visibility) {
                  if (visibility != null) {
                    _setTwonlyScoreVisibility(visibility);
                  }
                },
              ),
            ),
          ),
          ListTile(
            title: Text(context.lang.customAvatarPhotoTab),
            subtitle: Text(context.lang.customAvatarExplanation),
            trailing: SizedBox(
              width: 180,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<bool>(
                  isExpanded: true,
                  value: _customAvatar?.acceptedContactsOnly ?? true,
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text(context.lang.customAvatarAcceptedOnly),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text(context.lang.privacyVisibilityEveryone),
                    ),
                  ],
                  onChanged: _customAvatar == null || _updatingAvatarVisibility
                      ? null
                      : (acceptedOnly) {
                          if (acceptedOnly != null) {
                            _setCustomAvatarVisibility(acceptedOnly);
                          }
                        },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
