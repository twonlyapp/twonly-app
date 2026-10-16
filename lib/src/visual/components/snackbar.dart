import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

enum SnackbarLevel {
  info,
  success,
  warning,
  error,
}

void showSnackbar(
  BuildContext context,
  String message, {
  SnackbarLevel level = SnackbarLevel.error,
}) {
  final (backgroundColor, foregroundColor, iconData) = switch (level) {
    SnackbarLevel.info => (
      context.appColor(AppColor.info),
      context.appColor(AppColor.onInfo),
      Icons.info_outline,
    ),
    SnackbarLevel.success => (
      context.appColor(AppColor.success),
      context.appColor(AppColor.onSuccess),
      Icons.check_circle_outline,
    ),
    SnackbarLevel.warning => (
      context.appColor(AppColor.warning),
      context.appColor(AppColor.onWarning),
      Icons.warning_amber_rounded,
    ),
    SnackbarLevel.error => (
      context.color.error,
      context.color.onError,
      Icons.error_outline,
    ),
  };

  AnimationController? localAnimationController;

  _showOverlay(
    context: context,
    animationDuration: const Duration(milliseconds: 1000),
    reverseAnimationDuration: const Duration(milliseconds: 350),
    displayDuration: const Duration(milliseconds: 3000),
    onAnimationControllerInit: (controller) =>
        localAnimationController = controller,
    child: _SnackbarWidget(
      message: message,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      icon: Icon(iconData, color: foregroundColor, size: 28),
      onCloseClick: () {
        localAnimationController?.reverse();
      },
    ),
  );
}

OverlayEntry? _previousEntry;

void _showOverlay({
  required BuildContext context,
  required Widget child,
  required Duration animationDuration,
  required Duration reverseAnimationDuration,
  required Duration displayDuration,
  required void Function(AnimationController) onAnimationControllerInit,
}) {
  var overlayState = Overlay.maybeOf(context);
  if (overlayState == null) {
    if (context is StatefulElement && context.state is NavigatorState) {
      overlayState = (context.state as NavigatorState).overlay;
    }
  }
  if (overlayState == null) return;

  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (_) => _AnimatedSnackbar(
      animationDuration: animationDuration,
      reverseAnimationDuration: reverseAnimationDuration,
      displayDuration: displayDuration,
      onAnimationControllerInit: onAnimationControllerInit,
      onDismissed: () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
        if (_previousEntry == overlayEntry) {
          _previousEntry = null;
        }
      },
      child: child,
    ),
  );

  if (_previousEntry != null && _previousEntry!.mounted) {
    _previousEntry?.remove();
  }

  overlayState.insert(overlayEntry);
  _previousEntry = overlayEntry;
}

class _SnackbarWidget extends StatelessWidget {
  const _SnackbarWidget({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.onCloseClick,
  });
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final Icon icon;
  final VoidCallback onCloseClick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.hardEdge,
      constraints: const BoxConstraints(minHeight: 70),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 30,
          ),
        ],
      ),
      width: double.infinity,
      child: Row(
        children: [
          const SizedBox(width: 16),
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.merge(
                  TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: foregroundColor,
                  ),
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCloseClick,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.close,
                color: foregroundColor.withValues(alpha: 0.75),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSnackbar extends StatefulWidget {
  const _AnimatedSnackbar({
    required this.child,
    required this.onDismissed,
    required this.animationDuration,
    required this.reverseAnimationDuration,
    required this.displayDuration,
    required this.onAnimationControllerInit,
  });
  final Widget child;
  final VoidCallback onDismissed;
  final Duration animationDuration;
  final Duration reverseAnimationDuration;
  final Duration displayDuration;
  final void Function(AnimationController) onAnimationControllerInit;

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      reverseDuration: widget.reverseAnimationDuration,
    );

    _animationController.addStatusListener(_handleAnimationStatus);
    widget.onAnimationControllerInit(_animationController);

    _offsetAnimation =
        Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
            reverseCurve: Curves.linearToEaseOut,
          ),
        );

    _animationController.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _timer = Timer(widget.displayDuration, () {
        if (mounted) {
          _animationController.reverse();
        }
      });
    } else if (status == AnimationStatus.dismissed) {
      _timer?.cancel();
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: SafeArea(
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            dismissThresholds: const {DismissDirection.up: 0.2},
            confirmDismiss: (_) async {
              if (mounted) {
                await _animationController.reverse();
              }
              return false;
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
