import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:vector_graphics/vector_graphics.dart';

class AvatarIcon extends StatefulWidget {
  const AvatarIcon({
    super.key,
    this.group,
    this.contacts,
    this.contactId,
    this.myAvatar = false,
    this.fontSize = 20,
    this.svg,
    this.color,
  });
  final Group? group;
  final List<Contact>? contacts;
  final int? contactId;
  final bool myAvatar;
  final double? fontSize;
  final String? svg;
  final Color? color;

  @override
  State<AvatarIcon> createState() => _AvatarIconState();
}

/// Avatars are only ever drawn from PNG. Rasterising the stored SVG on the UI
/// thread is what made long chat lists stutter, so a missing PNG is rendered
/// once by Rust instead of being drawn as vector graphics every frame.
/// Keyed by contact plus profile counter, so a changed avatar naturally lands
/// on a fresh key.
final Map<String, String> _avatarPngPathCache = {};

/// Avatar paths already known to exist on disk. Only positive results are
/// cached: a PNG can still appear after a miss (it is written when the avatar
/// finishes downloading, or by the render below), so a miss stays re-checkable.
final Set<String> _existingAvatarPngPaths = {};

/// Contacts whose PNG render is already in flight, so a list that shows the
/// same contact in several rows asks Rust to render it only once.
final Map<int, Future<String?>> _pendingAvatarRenders = {};

/// Avatars Rust could not turn into a PNG, keyed by contact plus profile
/// counter so a broken SVG is not re-rendered on every stream tick while a
/// later avatar still gets its own attempt.
final Set<String> _unrenderableAvatars = {};

const _avatarCacheLimit = 200;

void _putBounded<T>(Map<String, T> cache, String key, T value) {
  if (cache.length >= _avatarCacheLimit) {
    cache.remove(cache.keys.first);
  }
  cache[key] = value;
}

String _avatarCacheKey(Contact contact) =>
    '${contact.userId}:${contact.senderProfileCounter}';

String _avatarPngPathFor(Contact contact) {
  final key = _avatarCacheKey(contact);
  final cached = _avatarPngPathCache[key];
  if (cached != null) return cached;
  final path = RustApi.avatarPngPath(
    contactId: contact.userId,
    profileCounter: contact.senderProfileCounter,
  );
  _putBounded(_avatarPngPathCache, key, path);
  return path;
}

class _AvatarIconState extends State<AvatarIcon> {
  List<Contact> _avatarContacts = [];
  Set<int> _contactsWithPngAvatar = {};
  String? _myAvatarPath;

  StreamSubscription<List<Contact>>? groupStream;
  StreamSubscription<List<Contact>>? contactsStream;
  StreamSubscription<Contact?>? contactStream;
  StreamSubscription<void>? _userSub;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didUpdateWidget(AvatarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare by value: callers commonly build a fresh list on every rebuild,
    // and an identity check would restart the avatar probe every frame.
    if (widget.contacts != null &&
        !listEquals(widget.contacts, oldWidget.contacts)) {
      _setAvatarContacts(widget.contacts!);
    }
  }

  void _setAvatarContacts(List<Contact> contacts) {
    _avatarContacts = contacts
        .where((contact) => contact.avatarSvgCompressed != null)
        .toList();
    unawaited(_refreshAvatarFiles());
    if (mounted) setState(() {});
  }

  Future<void> _refreshAvatarFiles() async {
    final available = <int>{};
    for (final contact in _avatarContacts) {
      final path = _avatarPngPathFor(contact);
      var exists = _existingAvatarPngPaths.contains(path);
      if (!exists) {
        // Async file access keeps avatar discovery off the UI thread.
        // ignore: avoid_slow_async_io
        exists = await File(path).exists();
        if (exists) _existingAvatarPngPaths.add(path);
      }
      if (exists) {
        available.add(contact.userId);
      } else if (!_unrenderableAvatars.contains(_avatarCacheKey(contact))) {
        // No PNG yet: render one rather than falling back to the SVG. The
        // default avatar is shown until it lands.
        unawaited(_renderAvatarPng(contact));
      }
    }
    if (!mounted) return;
    if (setEquals(_contactsWithPngAvatar, available)) return;
    setState(() => _contactsWithPngAvatar = available);
  }

  Future<void> _renderAvatarPng(Contact contact) async {
    final contactId = contact.userId;
    // Every widget showing this contact awaits the same render, so each one
    // still learns the path while Rust rasterises it only once.
    var render = _pendingAvatarRenders[contactId];
    if (render == null) {
      // Block body on purpose: returning `remove`'s value would hand
      // `whenComplete` the future it is completing and hang it.
      render = RustApi.ensureAvatarPng(contactId: contactId).whenComplete(() {
        _pendingAvatarRenders.remove(contactId);
      });
      _pendingAvatarRenders[contactId] = render;
    }

    String? path;
    try {
      path = await render;
    } catch (e) {
      Log.error('Failed to render avatar for $contactId: $e');
      _unrenderableAvatars.add(_avatarCacheKey(contact));
      return;
    }
    if (path == null) {
      _unrenderableAvatars.add(_avatarCacheKey(contact));
      return;
    }
    _existingAvatarPngPaths.add(path);
    if (!mounted) return;
    if (_contactsWithPngAvatar.contains(contactId)) return;
    if (!_avatarContacts.any((entry) => entry.userId == contactId)) return;
    setState(() {
      _contactsWithPngAvatar = {..._contactsWithPngAvatar, contactId};
    });
  }

  @override
  void dispose() {
    groupStream?.cancel();
    contactStream?.cancel();
    contactsStream?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  Widget errorBuilder(_, _, _) {
    return const SvgPicture(
      AssetBytesLoader('assets/images/default_avatar.svg.vec'),
    );
  }

  Widget getAvatarForContact(Contact contact) {
    if (_contactsWithPngAvatar.contains(contact.userId)) {
      return Image.file(
        File(_avatarPngPathFor(contact)),
        errorBuilder: errorBuilder,
      );
    }
    // Deliberately no SVG fallback: the render kicked off by
    // `_refreshAvatarFiles` swaps this placeholder for the PNG when it is done.
    return errorBuilder(null, null, null);
  }

  Future<void> initAsync() async {
    if (widget.contacts != null) {
      _setAvatarContacts(widget.contacts!);
    } else if (widget.group != null) {
      groupStream = twonlyDB.groupsDao
          .watchGroupContact(widget.group!.groupId)
          .listen((contacts) {
            _avatarContacts = [];
            if (contacts.length == 1) {
              if (contacts.first.avatarSvgCompressed != null) {
                _avatarContacts.add(contacts.first);
              }
            } else {
              for (final contact in contacts) {
                if (contact.avatarSvgCompressed != null) {
                  _avatarContacts.add(contact);
                }
              }
            }
            unawaited(_refreshAvatarFiles());
            setState(() {});
          });
    } else if (widget.myAvatar) {
      _userSub = userService.onUserUpdated.listen((_) {
        unawaited(_updateMyAvatar());
      });
      unawaited(_updateMyAvatar());
    } else if (widget.contactId != null) {
      contactStream = twonlyDB.contactsDao
          .watchContact(widget.contactId!)
          .listen((contact) {
            if (contact != null && contact.avatarSvgCompressed != null) {
              _avatarContacts = [contact];
              unawaited(_refreshAvatarFiles());
              setState(() {});
            }
          });
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateMyAvatar() async {
    final avatarSvg = userService.currentUser.avatarSvg;
    if (avatarSvg == null) {
      if (mounted) {
        setState(() {
          _myAvatarPath = null;
          _avatarContacts = [];
        });
      }
      return;
    }

    final path = await RustApi.currentUserAvatarPath();

    if (mounted) {
      setState(() {
        _myAvatarPath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final proSize = (widget.fontSize == null) ? 40 : (widget.fontSize! * 2);

    Widget avatars = Container();

    if (widget.myAvatar) {
      if (_myAvatarPath != null) {
        avatars = Image.file(
          File(_myAvatarPath!),
          errorBuilder: errorBuilder,
        );
      } else {
        avatars = const SvgPicture(
          AssetBytesLoader('assets/images/default_avatar.svg.vec'),
        );
      }
    } else if (_avatarContacts.length == 1) {
      avatars = getAvatarForContact(_avatarContacts.first);
    } else if (_avatarContacts.length >= 2) {
      final a = getAvatarForContact(_avatarContacts.first);
      final b = getAvatarForContact(_avatarContacts[1]);
      if (_avatarContacts.length >= 3) {
        final c = getAvatarForContact(_avatarContacts[2]);
        avatars = Stack(
          children: [
            Transform.translate(
              offset: const Offset(-15, 5),
              child: Transform.scale(
                scale: 0.8,
                child: c,
              ),
            ),
            Transform.translate(
              offset: const Offset(15, 5),
              child: Transform.scale(
                scale: 0.8,
                child: b,
              ),
            ),
            a,
          ],
        );
      } else {
        avatars = Stack(
          children: [
            Transform.translate(
              offset: const Offset(-10, 5),
              child: Transform.scale(
                scale: 0.8,
                child: b,
              ),
            ),
            Transform.translate(offset: const Offset(10, 0), child: a),
          ],
        );
      }
    } else if (widget.svg != null) {
      // Last resort for callers with no contact behind the avatar (the
      // passwordless recovery flow renders friends straight from a payload).
      // Anything backed by a contact has already been served as PNG above.
      avatars = SvgPicture.string(
        widget.svg!,
        errorBuilder: errorBuilder,
      );
    } else {
      avatars = const SvgPicture(
        AssetBytesLoader('assets/images/default_avatar.svg.vec'),
      );
    }

    return Container(
      constraints: BoxConstraints(
        minHeight: 2 * (widget.fontSize ?? 20),
        minWidth: 2 * (widget.fontSize ?? 20),
        maxWidth: 2 * (widget.fontSize ?? 20),
        maxHeight: 2 * (widget.fontSize ?? 20),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: proSize as double,
            width: proSize,
            color: widget.color,
            child: Center(child: avatars),
          ),
        ),
      ),
    );
  }
}
