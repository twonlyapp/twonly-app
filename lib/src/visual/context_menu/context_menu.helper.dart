import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';

/// Quick reactions shown in a bar above a lifted context menu.
class ContextMenuReactions {
  const ContextMenuReactions({
    required this.emojis,
    required this.onSelected,
    required this.onMore,
    required this.moreLabel,
    this.selected = const {},
  });

  final List<String> emojis;

  /// Emojis the user already reacted with; they get a highlight.
  final Set<String> selected;
  final Future<void> Function(String emoji) onSelected;

  /// Opens the full picker. Runs after the overlay has closed.
  final Future<void> Function() onMore;
  final String moreLabel;
}

class ContextMenu extends StatefulWidget {
  const ContextMenu({
    required this.child,
    required this.items,
    this.minWidth,
    this.lift = true,
    this.reactions,
    super.key,
  });

  /// Built on long press rather than eagerly: a context menu exists for every
  /// row in a list, and assembling the items can be costly (localized titles,
  /// closures, and in the message menu a filesystem probe).
  final List<ContextMenuItem> Function() items;
  final Widget child;
  final double? minWidth;

  /// Lifts a snapshot of [child] out of the list into the overlay and moves it
  /// to where the reaction bar and the menu both fit around it.
  final bool lift;

  /// Only used with [lift]. Returning null hides the bar.
  final ContextMenuReactions? Function()? reactions;

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu>
    with SingleTickerProviderStateMixin {
  Offset? _tapPosition;
  late final AnimationController _controller;
  final GlobalKey _boundaryKey = GlobalKey();
  final GlobalKey<_ContextMenuOverlayState> _overlayKey = GlobalKey();
  OverlayEntry? _entry;
  ui.Image? _snapshot;
  _OverlayPopEntry? _popEntry;
  ModalRoute<Object?>? _route;

  /// The original stays in the list but invisible while its snapshot is
  /// lifted, so the snapshot can fly back to it.
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
      value: 0,
    );
  }

  @override
  void dispose() {
    _removeOverlay(rebuild: false);
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _tapPosition = details.globalPosition;
    _controller.animateTo(
      1,
      duration: const Duration(milliseconds: 60),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails details) {
    _bounce();
  }

  void _onTapCancel() {
    _bounce();
  }

  void _bounce() {
    const spring = SpringDescription(
      mass: 1,
      stiffness: 400,
      damping: 15,
    );
    final simulation = SpringSimulation(
      spring,
      _controller.value,
      0,
      _controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  /// The child's current rectangle on screen, or null once it left the tree.
  Rect? _childRect() {
    final box = _boundaryKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
  }

  void _open() {
    if (_entry != null || _tapPosition == null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    unawaited(HapticFeedback.heavyImpact());
    _bounce();

    final items = widget.items();
    final reactions = widget.lift ? widget.reactions?.call() : null;

    Rect? origin;
    Size? childSize;
    if (widget.lift) {
      final box = _boundaryKey.currentContext?.findRenderObject();
      if (box is RenderRepaintBoundary && box.attached && box.hasSize) {
        origin = _childRect();
        childSize = box.size;
        try {
          _snapshot = box.toImageSync(
            pixelRatio: MediaQuery.devicePixelRatioOf(context),
          );
        } catch (_) {
          // A boundary that still needs paint cannot be captured. The menu
          // then opens over the row in place.
          _snapshot = null;
        }
      }
    }

    // Typing is over once a message is picked up; the keyboard would also eat
    // the room the menu needs.
    FocusManager.instance.primaryFocus?.unfocus();

    _entry = OverlayEntry(
      builder: (_) => _ContextMenuOverlay(
        key: _overlayKey,
        items: items,
        reactions: reactions,
        snapshot: _snapshot,
        origin: origin,
        childSize: childSize,
        tapPosition: _tapPosition!,
        minWidth: widget.minWidth,
        currentOrigin: _childRect,
        onItemSelected: (item) async {
          // The overlay can outlive its row. Only run the action while the
          // row's context and the contexts captured by it are still valid.
          if (!mounted) return;
          await item.onTap();
        },
        onReaction: (emoji) async {
          if (!mounted) return;
          await reactions?.onSelected(emoji);
        },
        onMoreReactions: () async {
          if (!mounted) return;
          await reactions?.onMore();
        },
        onClosed: _removeOverlay,
      ),
    );
    overlay.insert(_entry!);

    // Android back closes the menu instead of the chat.
    _route = ModalRoute.of(context);
    _popEntry = _OverlayPopEntry(() => _overlayKey.currentState?.close());
    _route?.registerPopEntry(_popEntry!);

    if (_snapshot != null) setState(() => _hidden = true);
  }

  void _removeOverlay({bool rebuild = true}) {
    final popEntry = _popEntry;
    if (popEntry != null) {
      _route?.unregisterPopEntry(popEntry);
      popEntry.dispose();
    }
    _popEntry = null;
    _route = null;
    _entry?.remove();
    _entry = null;
    final image = _snapshot;
    _snapshot = null;
    if (image != null) {
      // The last frame of the overlay may still reference the image.
      WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
    }
    if (rebuild && mounted && _hidden) setState(() => _hidden = false);
  }

  @override
  Widget build(BuildContext context) {
    // The finger that opened the menu stays on this row: sliding it picks an
    // emoji, lifting it sends it. Raw pointer events carry the timestamps a
    // swipe's speed is measured from; before the menu opens nothing listens.
    return Listener(
      onPointerMove: (event) => _overlayKey.currentState?.updateHeld(
        event.position,
        event.timeStamp,
      ),
      child: GestureDetector(
        onLongPress: _open,
        onLongPressEnd: (_) => _overlayKey.currentState?.endDrag(),
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        // AnimatedBuilder keeps the press animation from rebuilding the wrapped
        // row; only the Transform is re-evaluated per tick.
        child: AnimatedBuilder(
          animation: _controller,
          child: Opacity(
            opacity: _hidden ? 0 : 1,
            child: RepaintBoundary(key: _boundaryKey, child: widget.child),
          ),
          builder: (context, child) => Transform.scale(
            scale: 1.0 - (_controller.value * 0.02),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _OverlayPopEntry extends PopEntry<Object?> {
  _OverlayPopEntry(this.onBack);

  final VoidCallback onBack;
  final ValueNotifier<bool> _canPop = ValueNotifier(false);

  @override
  ValueListenable<bool> get canPopNotifier => _canPop;

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) onBack();
  }

  void dispose() => _canPop.dispose();
}

class ContextMenuItem {
  ContextMenuItem({
    required this.title,
    required this.onTap,
    required this.icon,
    this.destructive = false,
  });
  final String title;
  final Future<void> Function() onTap;
  final dynamic icon;

  /// Drawn in the error color, for deleting and the like.
  final bool destructive;
}

const double _screenMargin = 12;
const double _gap = 8;
const double _itemHeight = 48;
const double _menuPadding = 6;
const double _menuWidth = 236;
const double _barPadding = 6;
const double _maxSlot = 38;

class _ContextMenuOverlay extends StatefulWidget {
  const _ContextMenuOverlay({
    required this.items,
    required this.reactions,
    required this.snapshot,
    required this.origin,
    required this.childSize,
    required this.tapPosition,
    required this.minWidth,
    required this.currentOrigin,
    required this.onItemSelected,
    required this.onReaction,
    required this.onMoreReactions,
    required this.onClosed,
    super.key,
  });

  final List<ContextMenuItem> items;
  final ContextMenuReactions? reactions;
  final ui.Image? snapshot;
  final Rect? origin;
  final Size? childSize;
  final Offset tapPosition;
  final double? minWidth;
  final Rect? Function() currentOrigin;
  final Future<void> Function(ContextMenuItem item) onItemSelected;
  final Future<void> Function(String emoji) onReaction;
  final Future<void> Function() onMoreReactions;
  final VoidCallback onClosed;

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 90),
  );
  late final CurvedAnimation _fly = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  final GlobalKey _barKey = GlobalKey();
  late Rect? _origin = widget.origin;
  int? _hovered;
  bool _closing = false;

  /// Last position of the finger that opened the menu, while it is down.
  Offset? _heldAt;

  /// Whether that finger moved far enough to mean a pick. Lifting it in place
  /// keeps the menu open instead of reacting.
  bool _heldMoved = false;

  /// The bar only takes input once it stopped moving; a pick during the
  /// pop-in lands on whatever happened to slide under the finger.
  bool get _ready => _anim.isCompleted && !_closing;

  int get _slotCount => (widget.reactions?.emojis.length ?? 0) + 1;

  @override
  void initState() {
    super.initState();
    _anim
      ..addStatusListener((status) {
        // A finger that already moved while the bar animated in picks as soon
        // as it is ready, without waiting for the next move.
        final held = _heldAt;
        if (status.isCompleted && _heldMoved && held != null) {
          _pickWithHeld(held);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _fly.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    // The list may have moved underneath (new message, keyboard closing), so
    // fly back to where the original is now.
    final current = widget.currentOrigin();
    setState(() {
      _hovered = null;
      if (current != null) _origin = current;
    });
    await _anim.reverse();
    widget.onClosed();
  }

  /// Which bar slot a finger at [global] points at: the emojis by index, the
  /// more button last, null when it points at none. With [anywhere] only the
  /// horizontal position counts, so the held finger can pick from anywhere on
  /// the screen, the menu card included.
  int? _slotAt(Offset global, {required bool anywhere}) {
    final box = _barKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    if (!anywhere) {
      if (local.dy < -56 || local.dy > box.size.height + 40) return null;
      if (local.dx < -16 || local.dx > box.size.width + 16) return null;
    }
    final slot = (box.size.width - 2 * _barPadding) / _slotCount;
    return ((local.dx - _barPadding) / slot).floor().clamp(0, _slotCount - 1);
  }

  /// Bottom edge of the menu card. Below it the held finger's pick is
  /// always paused.
  double _pauseLine = double.infinity;

  /// A downward swipe at least this fast (logical px/s) pauses the pick
  /// anywhere; dragging slowly down onto the menu card does not.
  static const double _swipeSpeed = 900;

  /// While paused, moving back up this far (or swiping up) resumes the pick.
  static const double _resumeDistance = 40;

  final VelocityTracker _velocity = VelocityTracker.withKind(
    PointerDeviceKind.touch,
  );

  /// Paused: nothing is selected and letting go sends nothing.
  bool _paused = false;
  double _lowestWhilePaused = 0;

  /// The finger that opened the menu moved, still held down.
  void updateHeld(Offset global, Duration timeStamp) {
    _heldAt = global;
    _velocity.addPosition(timeStamp, global);
    if (!_heldMoved && (global - widget.tapPosition).distance < 12) return;
    _heldMoved = true;

    final speed = _velocity.getVelocityEstimate()?.pixelsPerSecond.dy ?? 0;
    if (!_paused) {
      if (speed > _swipeSpeed || global.dy > _pauseLine) {
        _paused = true;
        _lowestWhilePaused = global.dy;
      }
    } else {
      _lowestWhilePaused = math.max(_lowestWhilePaused, global.dy);
      final backUp =
          speed < -_swipeSpeed ||
          _lowestWhilePaused - global.dy > _resumeDistance;
      if (backUp && global.dy <= _pauseLine) _paused = false;
    }
    _pickWithHeld(global);
  }

  void _pickWithHeld(Offset global) {
    if (_paused) {
      if (_ready && _hovered != null) setState(() => _hovered = null);
      return;
    }
    updateDrag(global, anywhere: true);
  }

  void updateDrag(Offset global, {required bool anywhere}) {
    if (!_ready || widget.reactions == null) return;
    final slot = _slotAt(global, anywhere: anywhere);
    if (slot == _hovered) return;
    if (slot != null) unawaited(HapticFeedback.lightImpact());
    setState(() => _hovered = slot);
  }

  void endDrag() {
    _heldAt = null;
    _heldMoved = false;
    _paused = false;
    final slot = _hovered;
    if (slot == null || !_ready) return;
    unawaited(_activateSlot(slot));
  }

  Future<void> _activateSlot(int slot) async {
    final reactions = widget.reactions;
    if (reactions == null) return;
    if (slot < reactions.emojis.length) {
      unawaited(HapticFeedback.mediumImpact());
      unawaited(close());
      await widget.onReaction(reactions.emojis[slot]);
    } else {
      await close();
      await widget.onMoreReactions();
    }
  }

  Future<void> _selectItem(ContextMenuItem item) async {
    await close();
    await widget.onItemSelected(item);
  }

  double get _menuHeight =>
      widget.items.length * _itemHeight + 2 * _menuPadding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final topLimit = media.padding.top + _screenMargin;
    final bottomLimit =
        screen.height -
        math.max(media.padding.bottom, media.viewInsets.bottom) -
        _screenMargin;
    final menuWidth = math.min(
      math.max(widget.minWidth ?? 0, _menuWidth),
      screen.width - 2 * _screenMargin,
    );
    final hasMenu = widget.items.isNotEmpty;
    final menuHeight = hasMenu ? _menuHeight : 0.0;

    final origin = _origin;
    final childSize = widget.childSize;
    final lifted = origin != null && childSize != null;

    // Where the lifted child settles: as close to its spot in the list as
    // the bar above and the menu below allow. A child too tall for both
    // keeps its top and lets the menu overlap its lower part.
    Rect? target;
    var menuTop = 0.0;
    var menuLeft = 0.0;
    var alignRight = false;
    if (lifted) {
      final barSpace = widget.reactions != null
          ? _barHeight(screen.width) + _gap
          : 0.0;
      final menuSpace = hasMenu ? menuHeight + _gap : 0.0;
      var top = math.max(origin.top, topLimit + barSpace);
      if (top + childSize.height + menuSpace > bottomLimit) {
        top = bottomLimit - menuSpace - childSize.height;
      }
      top = math.max(top, topLimit + barSpace);
      target = Rect.fromLTWH(
        origin.center.dx - childSize.width / 2,
        top,
        childSize.width,
        childSize.height,
      );
      menuTop = math.min(target.bottom + _gap, bottomLimit - menuHeight);
      if (widget.reactions == null && childSize.width > screen.width * 0.8) {
        // A full-width row, such as a chat in the list: the menu opens under
        // the finger rather than at the row's edge.
        final tap = widget.tapPosition;
        alignRight = tap.dx > screen.width / 2;
        menuLeft = alignRight ? tap.dx - menuWidth : tap.dx;
      } else {
        alignRight = target.center.dx > screen.width / 2;
        menuLeft = alignRight ? target.right - menuWidth : target.left;
      }
    } else {
      final tap = widget.tapPosition;
      alignRight = tap.dx > screen.width / 2;
      menuTop = tap.dy + menuHeight > bottomLimit
          ? tap.dy - menuHeight
          : tap.dy;
      menuLeft = alignRight ? tap.dx - menuWidth : tap.dx;
    }
    menuTop = menuTop.clamp(
      topLimit,
      math.max(topLimit, bottomLimit - menuHeight),
    );
    menuLeft = menuLeft.clamp(
      _screenMargin,
      math.max(_screenMargin, screen.width - _screenMargin - menuWidth),
    );
    _pauseLine = hasMenu
        ? menuTop + menuHeight
        : (target?.bottom ?? double.infinity);

    return IgnorePointer(
      ignoring: _closing,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _fly.value;
          final children = <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: close,
                child: _Scrim(progress: _anim.value),
              ),
            ),
          ];

          if (lifted) {
            final rect = Rect.lerp(origin, target, t)!;
            if (widget.snapshot != null) {
              children.add(
                Positioned.fromRect(
                  rect: rect,
                  child: GestureDetector(
                    // A tap on the lifted message itself keeps the menu.
                    onTap: () {},
                    child: _LiftedSnapshot(
                      image: widget.snapshot!,
                      size: rect.size,
                      // A message bubble brings its own background. A list
                      // row, such as a chat, only paints its text and
                      // avatar, so without a card it looks dimmed too.
                      card: widget.reactions == null,
                    ),
                  ),
                ),
              );
            }
            if (widget.reactions != null) {
              final barHeight = _barHeight(screen.width);
              final barWidth = _barWidth(screen.width);
              var barLeft = alignRight ? rect.right - barWidth : rect.left;
              barLeft = barLeft.clamp(
                _screenMargin,
                math.max(
                  _screenMargin,
                  screen.width - _screenMargin - barWidth,
                ),
              );
              children.add(
                Positioned(
                  left: barLeft,
                  top: rect.top - _gap - barHeight,
                  width: barWidth,
                  height: barHeight,
                  child: _popIn(
                    alignment: alignRight
                        ? Alignment.bottomRight
                        : Alignment.bottomLeft,
                    child: IgnorePointer(
                      ignoring: !_ready,
                      child: _ReactionBar(
                        key: _barKey,
                        reactions: widget.reactions!,
                        hovered: _hovered,
                        appear: _anim,
                        slotSize: _slotSize(screen.width),
                        onDrag: (global) => updateDrag(global, anywhere: false),
                        onRelease: endDrag,
                        onTapSlot: _activateSlot,
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          if (hasMenu) {
            final top = lifted
                ? menuTop - (target!.top - Rect.lerp(origin, target, t)!.top)
                : menuTop;
            children.add(
              Positioned(
                left: menuLeft,
                top: top,
                width: menuWidth,
                child: _popIn(
                  alignment: alignRight
                      ? Alignment.topRight
                      : Alignment.topLeft,
                  child: _MenuCard(
                    items: widget.items,
                    onSelect: _selectItem,
                  ),
                ),
              ),
            );
          }

          return Stack(children: children);
        },
      ),
    );
  }

  Widget _popIn({required Alignment alignment, required Widget child}) {
    final scale = Curves.easeOutBack.transform(
      Curves.easeOut.transform(_anim.value),
    );
    return Opacity(
      opacity: Curves.easeOut.transform(_anim.value),
      child: Transform.scale(
        scale: 0.75 + 0.25 * scale,
        alignment: alignment,
        child: child,
      ),
    );
  }

  double _slotSize(double screenWidth) {
    final available = screenWidth - 2 * _screenMargin - 2 * _barPadding;
    return math.min(_maxSlot, available / _slotCount);
  }

  double _barWidth(double screenWidth) =>
      _slotSize(screenWidth) * _slotCount + 2 * _barPadding;

  double _barHeight(double screenWidth) =>
      _slotSize(screenWidth) + 2 * _barPadding;
}

class _LiftedSnapshot extends StatelessWidget {
  const _LiftedSnapshot({
    required this.image,
    required this.size,
    required this.card,
  });

  final ui.Image image;
  final Size size;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final picture = RawImage(
      image: image,
      width: size.width,
      height: size.height,
      fit: BoxFit.fill,
    );
    if (!card) return picture;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: picture,
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    // Only a small dark overlay: the chat stays sharp and in color behind
    // the lifted message, just a little dimmer.
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: Colors.black.withValues(alpha: (dark ? 0.35 : 0.15) * progress),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.reactions,
    required this.hovered,
    required this.appear,
    required this.slotSize,
    required this.onDrag,
    required this.onRelease,
    required this.onTapSlot,
    super.key,
  });

  final ContextMenuReactions reactions;
  final int? hovered;
  final Animation<double> appear;
  final double slotSize;
  final void Function(Offset global) onDrag;
  final VoidCallback onRelease;
  final Future<void> Function(int slot) onTapSlot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = reactions.emojis.length + 1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // A fresh finger can also slide across the bar.
      onPanStart: (details) => onDrag(details.globalPosition),
      onPanUpdate: (details) => onDrag(details.globalPosition),
      onPanEnd: (_) => onRelease(),
      onTapDown: (details) => onDrag(details.globalPosition),
      onTapUp: (_) => onRelease(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(slotSize),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_barPadding),
          child: Row(
            children: [
              for (var i = 0; i < count; i++)
                _ReactionSlot(
                  size: slotSize,
                  hovered: hovered == i,
                  dimmed: hovered != null && hovered != i,
                  // Staggered pop-in, left to right.
                  appear: Interval(
                    0.1 + i * 0.05,
                    0.6 + i * 0.05,
                    curve: Curves.easeOutBack,
                  ).transform(appear.value.clamp(0, 1)),
                  child: i < reactions.emojis.length
                      ? _EmojiFace(
                          emoji: reactions.emojis[i],
                          selected: reactions.selected.contains(
                            reactions.emojis[i],
                          ),
                          size: slotSize,
                        )
                      : Semantics(
                          button: true,
                          label: reactions.moreLabel,
                          child: Container(
                            margin: EdgeInsets.all(slotSize * 0.1),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.ellipsis,
                                size: slotSize * 0.4,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionSlot extends StatelessWidget {
  const _ReactionSlot({
    required this.size,
    required this.hovered,
    required this.dimmed,
    required this.appear,
    required this.child,
  });

  final double size;
  final bool hovered;
  final bool dimmed;
  final double appear;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: appear,
        child: AnimatedSlide(
          offset: Offset(0, hovered ? -0.3 : 0),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: hovered ? 1.3 : (dimmed ? 0.9 : 1),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutBack,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _EmojiFace extends StatelessWidget {
  const _EmojiFace({
    required this.emoji,
    required this.selected,
    required this.size,
  });

  final String emoji;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final face = EmojiAnimationComp.animatedIcons.containsKey(emoji)
        ? EmojiAnimationComp(emoji: emoji)
        : FittedBox(child: Text(emoji));
    return Container(
      decoration: selected
          ? BoxDecoration(
              // Neutral, a shade off the bar: darker in light mode, lighter
              // in dark mode.
              color: scheme.onSurface.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            )
          : null,
      padding: EdgeInsets.all(size * 0.12),
      child: face,
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items, required this.onSelect});

  final List<ContextMenuItem> items;
  final Future<void> Function(ContextMenuItem item) onSelect;

  Widget _icon(dynamic icon, Color color) {
    return icon is IconData
        ? Icon(icon, size: 18, color: color)
        : FaIcon(icon as FaIconData?, size: 18, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: _menuPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                InkWell(
                  onTap: () => onSelect(item),
                  child: SizedBox(
                    height: _itemHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Center(
                              child: _icon(
                                item.icon,
                                item.destructive
                                    ? scheme.error
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: item.destructive
                                    ? scheme.error
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
