import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_editor/data/layer.dart';
import 'package:twonly/src/views/components/emoji_picker.bottom.dart';
import 'package:twonly/src/views/chats/media_viewer_components/emoji_reactions_row.component.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

class ReactionButtons extends StatefulWidget {
  const ReactionButtons({
    required this.show,
    required this.textInputFocused,
    required this.mediaViewerDistanceFromBottom,
    required this.messageId,
    required this.groupId,
    required this.emojiKey,
    required this.hide,
    super.key,
  });

  final double mediaViewerDistanceFromBottom;
  final bool show;
  final bool textInputFocused;
  final GlobalKey<EmojiFloatWidgetState> emojiKey;
  final String messageId;
  final String groupId;
  final void Function() hide;

  @override
  State<ReactionButtons> createState() => _ReactionButtonsState();
}

class _ReactionButtonsState extends State<ReactionButtons> {
  int selectedShortReaction = -1;
  final GlobalKey _keyEmojiPicker = GlobalKey();

  List<String> selectedEmojis =
      EmojiAnimation.animatedIcons.keys.toList().sublist(0, 6);

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    if (gUser.preSelectedEmojies != null) {
      selectedEmojis = gUser.preSelectedEmojies!;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final firstRowEmojis = selectedEmojis.take(6).toList();
    final secondRowEmojis =
        selectedEmojis.length > 6 ? selectedEmojis.skip(6).toList() : [];

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200), // Animation duration
      bottom: widget.show
          ? (widget.textInputFocused
              ? 50
              : widget.mediaViewerDistanceFromBottom)
          : widget.mediaViewerDistanceFromBottom - 20,
      left: widget.show ? 0 : MediaQuery.sizeOf(context).width / 2,
      right: widget.show ? 0 : MediaQuery.sizeOf(context).width / 2,
      curve: Curves.linearToEaseOut,
      child: AnimatedOpacity(
        opacity: widget.show ? 1.0 : 0.0, // Fade in/out
        duration: const Duration(milliseconds: 150),
        child: Container(
          color: widget.show ? Colors.black.withAlpha(0) : Colors.transparent,
          padding:
              widget.show ? const EdgeInsets.symmetric(vertical: 32) : null,
          child: Column(
            children: [
              if (secondRowEmojis.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: secondRowEmojis
                      .map(
                        (emoji) => EmojiReactionWidget(
                          messageId: widget.messageId,
                          groupId: widget.groupId,
                          hide: widget.hide,
                          show: widget.show,
                          emoji: emoji as String,
                          emojiKey: widget.emojiKey,
                        ),
                      )
                      .toList(),
                ),
              if (secondRowEmojis.isNotEmpty) const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ...firstRowEmojis.map(
                    (emoji) => EmojiReactionWidget(
                      messageId: widget.messageId,
                      groupId: widget.groupId,
                      hide: widget.hide,
                      show: widget.show,
                      emoji: emoji,
                      emojiKey: widget.emojiKey,
                    ),
                  ),
                  GestureDetector(
                    key: _keyEmojiPicker,
                    onTap: () async {
                      // ignore: inference_failure_on_function_invocation
                      final layer = await showModalBottomSheet(
                        context: context,
                        backgroundColor: context.color.surface,
                        builder: (BuildContext context) {
                          return const EmojiPickerBottom();
                        },
                      ) as EmojiLayerData?;
                      if (layer == null) return;
                      await sendReaction(
                        widget.groupId,
                        widget.messageId,
                        layer.text,
                      );
                      widget.emojiKey.currentState?.spawn(
                        getGlobalOffset(_keyEmojiPicker),
                        layer.text,
                      );
                      widget.hide();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.color.surfaceContainer.withAlpha(100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const FaIcon(
                        FontAwesomeIcons.ellipsisVertical,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmojiFloatWidget extends StatefulWidget {
  const EmojiFloatWidget({
    super.key,
  });
  @override
  EmojiFloatWidgetState createState() => EmojiFloatWidgetState();
}

class EmojiFloatWidgetState extends State<EmojiFloatWidget>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = [];
  late final Ticker _ticker;
  final Random _rnd = Random();
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = (_lastTick == Duration.zero)
        ? 0.016
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    for (final p in List<_Particle>.from(_particles)) {
      p.update(dt);
      if (p.isDead) _particles.remove(p);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Call this to spawn the emoji animation from a global screen position.
  void spawn(Offset globalPosition, String emoji) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    const spawnCount = 10;
    final life = const Duration(milliseconds: 2000).inMilliseconds / 1000.0;

    for (var i = 0; i < spawnCount; i++) {
      final dx = (_rnd.nextDouble() - 0.5) * 220;
      final vx = dx;
      final vy = -(100 + _rnd.nextDouble() * 80);
      final rot = (_rnd.nextDouble() - 0.5) * 2;
      final scale = 0.9 + _rnd.nextDouble() * 0.6;

      _particles.add(
        _Particle(
          emoji: emoji,
          x: local.dx,
          y: local.dy,
          vx: vx,
          vy: vy,
          rotation: rot,
          lifetime: life,
          scale: scale,
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(List<_Particle>.from(_particles)),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.emoji,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.lifetime,
    required this.scale,
  });
  final String emoji;
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double age = 0;
  final double lifetime;
  final double scale;
  bool get isDead => age >= lifetime;

  void update(double dt) {
    age += dt;
    // vertical-only motion emphasis: mild gravity slows ascent then gently pulls down
    vy += 100 * dt; // gravity (positive = down)
    // slight horizontal drag to reduce sideways drift
    vx *= 1 - 3.0 * dt;
    // integrate position
    x += vx * dt;
    y += vy * dt;
    // slow rotation decay
    rotation *= 1 - 1.5 * dt;
  }

  double get progress => (age / lifetime).clamp(0.0, 1.0);

  // opacity falls from 1 -> 0 as particle ages
  double get opacity => (1.0 - progress).clamp(0.0, 1.0);

  // scale can gently grow then shrink; here we slightly increase early
  double get currentScale {
    final p = progress;
    if (p < 0.5) return scale * (1.0 + 0.3 * (p / 0.5));
    return scale * (1.3 - 0.3 * ((p - 0.5) / 0.5));
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles);
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final p in particles) {
      final tp = TextSpan(
        text: p.emoji,
        style: TextStyle(
          fontSize: 24 * p.currentScale,
          color: Colors.black.withValues(alpha: p.opacity),
        ),
      );
      textPainter
        ..text = tp
        ..layout();
      canvas
        ..save()
        ..translate(p.x - textPainter.width / 2, p.y - textPainter.height / 2)
        ..rotate(p.rotation);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
