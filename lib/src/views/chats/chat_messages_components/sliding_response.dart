import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SlidingResponse extends StatefulWidget {
  final Widget child;
  final VoidCallback onResponseTriggered;

  const SlidingResponse({
    super.key,
    required this.child,
    required this.onResponseTriggered,
  });

  @override
  State<SlidingResponse> createState() => _SlidingResponseWidgetState();
}

class _SlidingResponseWidgetState extends State<SlidingResponse> {
  double _offset = 0.0;
  bool gotFeedback = false;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta.dx;
      if (_offset > 40) {
        _offset = 40;
        if (!gotFeedback) {
          HapticFeedback.heavyImpact();
          gotFeedback = true;
        }
      }
      if (_offset < 30) {
        gotFeedback = false;
      }
      if (_offset <= 0) _offset = 0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_offset >= 40) {
      widget.onResponseTriggered();
    }
    setState(() {
      _offset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(_offset, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: widget.child,
          ),
        ),
        if (_offset >= 40)
          Positioned(
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
