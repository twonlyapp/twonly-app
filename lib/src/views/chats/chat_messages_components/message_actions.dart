import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly_database.dart';

class MessageActions extends StatefulWidget {
  const MessageActions({
    required this.child,
    required this.message,
    required this.onResponseTriggered,
    super.key,
  });
  final Widget child;
  final Message message;
  final VoidCallback onResponseTriggered;

  @override
  State<MessageActions> createState() => _SlidingResponseWidgetState();
}

class _SlidingResponseWidgetState extends State<MessageActions> {
  double _offsetX = 0;
  bool gotFeedback = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offsetX += details.delta.dx;
      if (_offsetX > 40) {
        _offsetX = 40;
        if (!gotFeedback) {
          unawaited(HapticFeedback.heavyImpact());
          gotFeedback = true;
        }
      }
      if (_offsetX < 30) {
        gotFeedback = false;
      }
      if (_offsetX <= 0) _offsetX = 0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_offsetX >= 40) {
      widget.onResponseTriggered();
    }
    setState(() {
      _offsetX = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(_offsetX, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: widget.child,
          ),
        ),
        if (_offsetX >= 40)
          const Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.reply,
                  size: 14,
                  // color: Colors.green,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
