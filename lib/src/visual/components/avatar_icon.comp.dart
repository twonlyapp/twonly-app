import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:flutter_svg/svg.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:vector_graphics/vector_graphics.dart';

class AvatarIcon extends StatefulWidget {
  const AvatarIcon({
    super.key,
    this.group,
    this.contacts,
    this.chatContacts,
    this.contactId,
    this.myAvatar = false,
    this.fontSize = 20,
    this.svg,
    this.color,
  });
  final Group? group;
  final List<Contact>? contacts;
  final List<ChatListContact>? chatContacts;
  final int? contactId;
  final bool myAvatar;
  final double? fontSize;
  final String? svg;
  final Color? color;

  @override
  State<AvatarIcon> createState() => _AvatarIconState();
}

/// Last resolved paths let recreated list rows draw an avatar while Rust
/// refreshes it. Only successful results are cached; misses remain retryable.
final Map<String, String> _avatarPathCache = {};
final Map<String, Future<String?>> _pendingAvatarRenders = {};
const _avatarCacheLimit = 200;

// A received photo can change without changing the public profile counter.
// Share one native invalidation stream across all visible contact avatars.
StreamSubscription<List<String>>? _avatarDatabaseChanges;
final StreamController<List<String>> _avatarChanges = StreamController.broadcast(
  onListen: () {
    var first = true;
    _avatarDatabaseChanges = watchRustDatabaseChanges().listen(
      (tables) {
        // Mounted rows already resolve once before this initial invalidation.
        if (first) {
          first = false;
          if (tables.isEmpty) return;
        }
        if (tables.isEmpty ||
            tables.contains('received_custom_avatars') ||
            tables.contains('own_custom_avatar')) {
          _avatarChanges.add(tables);
        }
      },
      onError: (Object error) {
        Log.warn('Could not watch avatar changes: $error');
      },
    );
  },
  onCancel: () {
    unawaited(_avatarDatabaseChanges?.cancel());
    _avatarDatabaseChanges = null;
  },
);

void _cacheAvatarPath(String key, String path) {
  if (!_avatarPathCache.containsKey(key) &&
      _avatarPathCache.length >= _avatarCacheLimit) {
    _avatarPathCache.remove(_avatarPathCache.keys.first);
  }
  _avatarPathCache[key] = path;
}

typedef _AvatarContact = ({
  int userId,
  int profileCounter,
  bool? preferPhotoAvatar,
  bool hasSvgAvatar,
});

_AvatarContact _contactAvatarKey(Contact contact) => (
  userId: contact.userId,
  profileCounter: contact.senderProfileCounter,
  preferPhotoAvatar: contact.preferPhotoAvatar,
  hasSvgAvatar: contact.avatarSvgCompressed?.isNotEmpty ?? false,
);

_AvatarContact _chatContactAvatarKey(ChatListContact contact) => (
  userId: contact.userId,
  profileCounter: contact.senderProfileCounter,
  preferPhotoAvatar: contact.preferPhotoAvatar,
  hasSvgAvatar: contact.hasSvgAvatar,
);

String _avatarCacheKey(_AvatarContact contact) =>
    '${contact.userId}:${contact.profileCounter}:${contact.preferPhotoAvatar}:${contact.hasSvgAvatar}';

class _AvatarIconState extends State<AvatarIcon> with WidgetsBindingObserver {
  double get _avatarSize => 2 * (widget.fontSize ?? 20);

  bool _isPhotoAvatar(String? path) => path?.endsWith('.webp') ?? false;

  Widget _avatarImage(String path) {
    final image = Image.file(
      File(path),
      width: _avatarSize,
      height: _avatarSize,
      errorBuilder: errorBuilder,
    );
    if (!_isPhotoAvatar(path)) return image;
    return Transform.scale(
      scale: (_avatarSize + 10) / _avatarSize,
      child: image,
    );
  }

  List<_AvatarContact> _avatarContacts = [];
  Map<int, List<int>?> _avatarSvgSources = {};
  final Map<String, String> _resolvedAvatarPaths = {};
  final Set<String> _failedAvatarKeys = {};
  Timer? _avatarRetry;
  int _retryAttempt = 0;
  int _sourceGeneration = 0;
  String? _myAvatarPath;

  StreamSubscription<List<Contact>>? groupStream;
  StreamSubscription<List<Contact>>? contactsStream;
  StreamSubscription<Contact?>? contactStream;
  StreamSubscription<void>? _userSub;
  StreamSubscription<List<String>>? _photoSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initAsync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAvatarFiles());
      if (widget.myAvatar) unawaited(_updateMyAvatar());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _avatarRetry?.cancel();
      _avatarRetry = null;
    }
  }

  @override
  void didUpdateWidget(AvatarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.contacts == null) != (oldWidget.contacts == null) ||
        (widget.chatContacts == null) != (oldWidget.chatContacts == null) ||
        widget.group?.groupId != oldWidget.group?.groupId ||
        widget.contactId != oldWidget.contactId ||
        widget.myAvatar != oldWidget.myAvatar) {
      _cancelSources();
      _avatarContacts = [];
      _resolvedAvatarPaths.clear();
      _failedAvatarKeys.clear();
      initAsync();
      return;
    }
    if (widget.chatContacts != null) {
      _setAvatarContacts(
        widget.chatContacts!.map(_chatContactAvatarKey).toList(),
      );
    } else if (widget.contacts != null) {
      _setContacts(widget.contacts!);
    }
  }

  void _setContacts(List<Contact> contacts) {
    // Legacy callers pass full contacts. Detect actual byte changes rather
    // than buffer identity, including a payload arriving at the same counter.
    final previous = _avatarContacts.toSet();
    final changed = contacts
        .where(
          (contact) =>
              previous.contains(_contactAvatarKey(contact)) &&
              !listEquals(
                _avatarSvgSources[contact.userId],
                contact.avatarSvgCompressed,
              ),
        )
        .toList();
    _avatarSvgSources = {
      for (final contact in contacts)
        contact.userId: contact.avatarSvgCompressed,
    };
    _setAvatarContacts(contacts.map(_contactAvatarKey).toList());
    for (final contact in changed) {
      unawaited(_renderAvatarPng(_contactAvatarKey(contact)));
    }
  }

  void _setAvatarContacts(List<_AvatarContact> contacts) {
    // Byte fields in generated Contact equality use identity. Only these
    // ordered keys determine the rendered avatars; photo changes invalidate
    // independently through the shared database stream.
    if (listEquals(_avatarContacts, contacts)) return;
    final previousKeys = _avatarContacts.map(_avatarCacheKey).toSet();
    _avatarContacts = contacts;
    final keys = contacts.map(_avatarCacheKey).toSet();
    _resolvedAvatarPaths.removeWhere((key, _) => !keys.contains(key));
    _failedAvatarKeys.retainAll(keys);
    for (final contact in contacts) {
      if (!previousKeys.contains(_avatarCacheKey(contact))) {
        unawaited(_renderAvatarPng(contact));
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _refreshAvatarFiles() async {
    for (final contact in _avatarContacts) {
      unawaited(_renderAvatarPng(contact));
    }
  }

  bool _showsAvatar(String key) =>
      mounted &&
      _avatarContacts.any((contact) => _avatarCacheKey(contact) == key);

  void _setAvatarPath(String key, String? path) {
    if (!_showsAvatar(key) || _resolvedAvatarPaths[key] == path) return;
    setState(() {
      if (path == null) {
        _resolvedAvatarPaths.remove(key);
      } else {
        _resolvedAvatarPaths[key] = path;
      }
    });
  }

  void _retryAvatar(String key, Object error) {
    if (!_showsAvatar(key)) return;
    final message = error.toString().toLowerCase();
    if (!message.contains('closed pool') &&
        !message.contains('pool timed out') &&
        !message.contains('database operation cancelled') &&
        !message.contains('interrupted') &&
        !message.contains('database is locked')) {
      return;
    }
    _failedAvatarKeys.add(key);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (_avatarRetry != null ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    final delay = Duration(seconds: 1 << _retryAttempt.clamp(0, 5));
    _retryAttempt++;
    _avatarRetry = Timer(delay, () {
      _avatarRetry = null;
      if (!mounted) return;
      for (final contact in _avatarContacts) {
        if (_failedAvatarKeys.contains(_avatarCacheKey(contact))) {
          unawaited(_renderAvatarPng(contact));
        }
      }
    });
  }

  Future<void> _renderAvatarPng(_AvatarContact contact) async {
    final key = _avatarCacheKey(contact);
    final cached = _avatarPathCache[key];
    if (cached != null) {
      if (File(cached).existsSync()) {
        _setAvatarPath(key, cached);
      } else {
        _avatarPathCache.remove(key);
        _setAvatarPath(key, null);
      }
    }
    if (!_showsAvatar(key)) return;

    String? path;
    try {
      // Every visible copy of a contact awaits the same native resolution.
      final render = _pendingAvatarRenders.putIfAbsent(
        key,
        () =>
            RustApi.ensureAvatarPng(contactId: contact.userId).whenComplete(() {
              _pendingAvatarRenders.remove(key);
            }),
      );
      path = await render;
    } catch (error) {
      Log.error('Failed to render avatar for ${contact.userId}: $error');
      _retryAvatar(key, error);
      return;
    }

    _failedAvatarKeys.remove(key);
    if (_failedAvatarKeys.isEmpty) {
      _avatarRetry?.cancel();
      _avatarRetry = null;
      _retryAttempt = 0;
    }
    if (path == null) {
      _avatarPathCache.remove(key);
    } else {
      _cacheAvatarPath(key, path);
    }
    _setAvatarPath(key, path);
  }

  void _cancelSources() {
    groupStream?.cancel();
    groupStream = null;
    contactStream?.cancel();
    contactStream = null;
    contactsStream?.cancel();
    contactsStream = null;
    _userSub?.cancel();
    _userSub = null;
    _photoSub?.cancel();
    _photoSub = null;
    _avatarRetry?.cancel();
    _avatarRetry = null;
    _retryAttempt = 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sourceGeneration++;
    _cancelSources();
    super.dispose();
  }

  Widget errorBuilder(_, _, _) {
    return const SvgPicture(
      AssetBytesLoader('assets/images/default_avatar.svg.vec'),
    );
  }

  Widget getAvatarForContact(_AvatarContact contact) {
    final key = _avatarCacheKey(contact);
    final path = _resolvedAvatarPaths[key] ?? _avatarPathCache[key];
    return path == null ? errorBuilder(null, null, null) : _avatarImage(path);
  }

  Future<void> initAsync() async {
    final generation = ++_sourceGeneration;
    bool active() => mounted && generation == _sourceGeneration;
    if (!widget.myAvatar &&
        (widget.contacts != null ||
            widget.chatContacts != null ||
            widget.group != null ||
            widget.contactId != null)) {
      _photoSub = _avatarChanges.stream.listen((tables) {
        if (active() &&
            (tables.isEmpty || tables.contains('received_custom_avatars'))) {
          unawaited(_refreshAvatarFiles());
        }
      });
    }
    if (widget.chatContacts != null) {
      _setAvatarContacts(
        widget.chatContacts!.map(_chatContactAvatarKey).toList(),
      );
    } else if (widget.contacts != null) {
      _setContacts(widget.contacts!);
    } else if (widget.group != null) {
      groupStream =
          watchRustDatabase(
                (control) => rust_groups
                    .watchGroupContacts(
                      input: db_groups.GroupMembersQuery(
                        groupId: widget.group!.groupId,
                        orderForChats: true,
                      ),
                      control: control,
                    )
                    .map(joinedGroupContacts),
              )
              .map((rows) => rows.map((row) => row.$1).toList(growable: false))
              .listen((
                contacts,
              ) {
                if (!active()) return;
                _setContacts(contacts);
              });
    } else if (widget.myAvatar) {
      var avatarKey = _myAvatarKey;
      _userSub = userService.onUserUpdated.listen((_) {
        final next = _myAvatarKey;
        if (next == avatarKey) return;
        avatarKey = next;
        unawaited(_updateMyAvatar());
      });
      _photoSub = _avatarChanges.stream.listen((tables) {
        if (active() &&
            (tables.isEmpty || tables.contains('own_custom_avatar'))) {
          unawaited(_updateMyAvatar());
        }
      });
      unawaited(_updateMyAvatar());
    } else if (widget.contactId != null) {
      contactStream =
          watchRustDatabase(
            (control) => rust_contacts.watchContacts(
              input: db_contacts.ContactQuery(
                filter: db_contacts.ContactFilter.ids,
                ids: Int64List.fromList([widget.contactId!].toList()),
              ),
              control: control,
            ),
          ).map((rows) => rows.isEmpty ? null : rows.single).listen((
            contact,
          ) {
            if (!active()) return;
            _setContacts(contact == null ? [] : [contact]);
          });
    }
    if (mounted) setState(() {});
  }

  (int, int, String?) get _myAvatarKey => (
    userService.currentUser.userId,
    userService.currentUser.avatarCounter,
    userService.currentUser.avatarSvg,
  );

  Future<void> _updateMyAvatar() async {
    // Rust resolves photo avatars as well as public SVG avatars, including
    // profiles that have only a photo avatar.
    try {
      final path = await RustApi.currentUserAvatarPath();

      if (mounted) {
        setState(() {
          _myAvatarPath = path;
        });
      }
    } catch (error) {
      Log.error('Failed to load own avatar: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final proSize = _avatarSize;

    Widget avatars = Container();

    if (widget.myAvatar) {
      if (_myAvatarPath != null) {
        avatars = _avatarImage(_myAvatarPath!);
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
        minHeight: proSize,
        minWidth: proSize,
        maxWidth: proSize,
        maxHeight: proSize,
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: proSize,
            width: proSize,
            color: widget.color,
            child: Center(child: avatars),
          ),
        ),
      ),
    );
  }
}
