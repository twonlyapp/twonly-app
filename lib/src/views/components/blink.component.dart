import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class BlinkWidget extends StatefulWidget {
  const BlinkWidget({
    required this.child,
    required this.enabled,
    super.key,
    this.blinkDuration = const Duration(milliseconds: 2000),
    this.interval = const Duration(milliseconds: 300),
    this.visibleOpacity = 1.0,
    this.hiddenOpacity = 0.05,
  });
  final bool enabled;
  final Widget child;
  final Duration blinkDuration;
  final Duration interval;
  final double visibleOpacity;
  final double hiddenOpacity;

  @override
  State<BlinkWidget> createState() => _BlinkWidgetState();
}

class _BlinkWidgetState extends State<BlinkWidget>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(covariant BlinkWidget oldWidget) {
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _ticker
          ..stop()
          ..start();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  void _onTick(Duration elapsed) {
    var visible = true;
    if (elapsed.inMilliseconds < widget.blinkDuration.inMilliseconds) {
      visible = elapsed.inMilliseconds % (widget.interval.inMilliseconds * 2) <
          widget.interval.inMilliseconds;
    } else {
      _ticker.stop();
    }
    setState(() => _visible = visible);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? widget.visibleOpacity : widget.hiddenOpacity,
      duration: Duration(
        milliseconds: widget.blinkDuration.inMilliseconds ~/ 3,
      ),
      child: widget.child,
    );
  }
}
