import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

typedef TextLabelBuilder = Widget Function(String label);

class DraggableScrollbar extends StatefulWidget {
  const DraggableScrollbar({
    required this.controller,
    required this.child,
    this.labelBuilder,
    super.key,
  });
  final ScrollController controller;
  final Widget child;
  final String? Function(double scrollOffset)? labelBuilder;

  @override
  State<DraggableScrollbar> createState() => _DraggableScrollbarState();

  static const double labelThumbPadding = 16;
}

class _DraggableScrollbarState extends State<DraggableScrollbar>
    with TickerProviderStateMixin {
  final ValueNotifier<double> _thumbOffsetNotifier = ValueNotifier(0);
  final ValueNotifier<double> _viewOffsetNotifier = ValueNotifier(0);
  bool _isDragInProcess = false;
  double _boundlessThumbOffset = 0;

  late AnimationController _thumbAnimationController;
  late CurvedAnimation _thumbAnimation;
  late AnimationController _labelAnimationController;
  late CurvedAnimation _labelAnimation;
  Timer? _fadeoutTimer;

  static const double thumbHeight = 60;
  static const double thumbWidth = 20;

  @override
  void initState() {
    super.initState();

    _thumbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _thumbAnimation = CurvedAnimation(
      parent: _thumbAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    _labelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _labelAnimation = CurvedAnimation(
      parent: _labelAnimationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _thumbOffsetNotifier.dispose();
    _viewOffsetNotifier.dispose();
    _thumbAnimation.dispose();
    _thumbAnimationController.dispose();
    _labelAnimation.dispose();
    _labelAnimationController.dispose();
    _fadeoutTimer?.cancel();
    super.dispose();
  }

  ScrollController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _onScrollNotification(notification);
        return false;
      },
      child: Stack(
        children: [
          RepaintBoundary(
            child: widget.child,
          ),
          // Scrollbar layer restricted to SafeArea
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxThumbOffset = constraints.maxHeight - thumbHeight;

                return ExcludeSemantics(
                  child: RepaintBoundary(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _thumbOffsetNotifier,
                      builder: (context, thumbOffset, child) {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        final handleColor = isDark
                            ? Colors.grey.shade900
                            : Colors.white;
                        final iconColor = isDark
                            ? Colors.white70
                            : Colors.black54;

                        final label = widget.labelBuilder?.call(
                          _viewOffsetNotifier.value,
                        );

                        return Container(
                          alignment: AlignmentDirectional.topEnd,
                          padding: EdgeInsets.only(top: thumbOffset),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragStart: (_) => _onVerticalDragStart(),
                            onVerticalDragUpdate: (details) =>
                                _onVerticalDragUpdate(
                                  details.delta.dy,
                                  maxThumbOffset,
                                ),
                            onVerticalDragEnd: (_) => _onVerticalDragEnd(),
                            child: SlideFadeTransition(
                              animation: _thumbAnimation,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (label != null && _isDragInProcess)
                                    FadeTransition(
                                      opacity: _labelAnimation,
                                      child: ScaleTransition(
                                        scale: _labelAnimation,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            right: DraggableScrollbar
                                                .labelThumbPadding,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (isDark
                                                        ? Colors.grey.shade900
                                                        : Colors.grey.shade200)
                                                    .withValues(alpha: 0.95),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.2,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Container(
                                    width: thumbWidth,
                                    height: thumbHeight,
                                    decoration: BoxDecoration(
                                      color: handleColor,
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.black12,
                                        width: 0.5,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: FaIcon(
                                            FontAwesomeIcons.angleUp,
                                            size: 14,
                                            color: iconColor,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: FaIcon(
                                            FontAwesomeIcons.angleDown,
                                            size: 14,
                                            color: iconColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onScrollNotification(ScrollNotification notification) {
    final scrollMetrics = notification.metrics;
    if (scrollMetrics.minScrollExtent >= scrollMetrics.maxScrollExtent) return;

    _viewOffsetNotifier.value = scrollMetrics.pixels;

    if (!_isDragInProcess) {
      if (notification is ScrollUpdateNotification) {
        // Find constraints and update thumb offset
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;

          // Subtract SafeArea top/bottom
          final padding = MediaQuery.paddingOf(context);
          final availableHeight = renderBox.size.height - padding.vertical;
          final maxThumbOffset = availableHeight - thumbHeight;

          final scrollExtent =
              scrollMetrics.pixels /
              scrollMetrics.maxScrollExtent *
              maxThumbOffset;
          _thumbOffsetNotifier.value = scrollExtent.clamp(0.0, maxThumbOffset);
        });
      }

      if (notification is ScrollUpdateNotification ||
          notification is OverscrollNotification) {
        _showThumb();
        _scheduleFadeout();
      }
    }
  }

  void _onVerticalDragStart() {
    _boundlessThumbOffset = _thumbOffsetNotifier.value;
    _labelAnimationController.forward();
    _fadeoutTimer?.cancel();
    _showThumb();
    setState(() => _isDragInProcess = true);
  }

  void _onVerticalDragUpdate(double deltaY, double maxThumbOffset) {
    _showThumb();
    if (_isDragInProcess && maxThumbOffset > 0) {
      _boundlessThumbOffset += deltaY;
      _thumbOffsetNotifier.value = _boundlessThumbOffset.clamp(
        0.0,
        maxThumbOffset,
      );

      final max = controller.position.maxScrollExtent;
      final scrollOffset = (_thumbOffsetNotifier.value / maxThumbOffset) * max;
      controller.jumpTo(
        scrollOffset.clamp(0.0, controller.position.maxScrollExtent),
      );
    }
  }

  void _onVerticalDragEnd() {
    _scheduleFadeout();
    setState(() => _isDragInProcess = false);
  }

  void _showThumb() {
    if (_thumbAnimationController.status != AnimationStatus.forward) {
      _thumbAnimationController.forward();
    }
  }

  void _scheduleFadeout() {
    _fadeoutTimer?.cancel();
    _fadeoutTimer = Timer(const Duration(milliseconds: 1500), () {
      _thumbAnimationController.reverse();
      _labelAnimationController.reverse();
      _fadeoutTimer = null;
    });
  }
}

class SlideFadeTransition extends StatelessWidget {
  const SlideFadeTransition({
    required this.animation,
    required this.child,
    super.key,
  });
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: child,
        );
      },
      child: child,
    );
  }
}
