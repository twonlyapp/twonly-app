import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';

class MessageReplyDrag extends StatefulWidget {
  const MessageReplyDrag({
    required this.child,
    required this.message,
    required this.onResponseTriggered,
    super.key,
  });
  final Widget child;
  final Message message;
  final VoidCallback onResponseTriggered;

  @override
  State<MessageReplyDrag> createState() => _SlidingResponseWidgetState();
}

class _SlidingResponseWidgetState extends State<MessageReplyDrag> {
  double _offsetX = 0;
  bool gotFeedback = false;
  double _dragProgress = 0;
  double _animatedScale = 1;

  Future<void> _triggerPopAnimation() async {
    setState(() {
      _animatedScale = 1.3;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      setState(() {
        _animatedScale = 1.0;
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offsetX += details.delta.dx;
      if (_offsetX <= 0) _offsetX = 0;
      if (_offsetX > 40) {
        if (!gotFeedback) {
          unawaited(HapticFeedback.heavyImpact());
          gotFeedback = true;
          unawaited(_triggerPopAnimation());
        }
        _dragProgress = 1;
      } else {
        _dragProgress = _offsetX / 40;
      }
      if (_offsetX < 30) {
        gotFeedback = false;
      }
      if (_offsetX > 50) {
        _offsetX = 50;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_offsetX >= 40) {
      widget.onResponseTriggered();
    }
    setState(() {
      _offsetX = 0.0;
      _dragProgress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_dragProgress > 0.2)
          Positioned(
            left: _dragProgress * 10,
            top: 0,
            bottom: 0,
            child: Transform.scale(
              scale: 1 * _dragProgress,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 50),
                scale: _animatedScale,
                curve: Curves.easeInOut,
                child: Opacity(
                  opacity: 1 * _dragProgress,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.reply,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(_offsetX, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
