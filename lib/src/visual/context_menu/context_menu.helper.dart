import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContextMenu extends StatefulWidget {
  const ContextMenu({
    required this.child,
    required this.items,
    this.minWidth,
    super.key,
  });

  final List<ContextMenuItem> items;
  final Widget child;
  final double? minWidth;

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu>
    with SingleTickerProviderStateMixin {
  Offset? _tapPosition;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          lowerBound: double.negativeInfinity,
          upperBound: double.infinity,
          value: 0,
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void dispose() {
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

  Widget _getIcon(dynamic icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: icon is IconData
          ? Icon(
              icon,
              size: 20,
            )
          : FaIcon(
              icon as FaIconData?,
              size: 20,
            ),
    );
  }

  Future<void> _showCustomMenu() async {
    if (_tapPosition == null) {
      return;
    }
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay == null) {
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    _bounce();

    await showMenu(
      context: context,
      menuPadding: EdgeInsetsGeometry.zero,
      elevation: 1,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration.zero,
        curve: Curves.fastOutSlowIn,
      ),
      items: <PopupMenuEntry<int>>[
        ...widget.items.map(
          (item) {
            Widget child = ListTile(
              title: Text(item.title),
              onTap: () async {
                if (mounted) Navigator.pop(context);
                await item.onTap();
              },
              leading: _getIcon(item.icon),
            );
            if (widget.minWidth != null) {
              child = ConstrainedBox(
                constraints: BoxConstraints(minWidth: widget.minWidth!),
                child: child,
              );
            }
            return PopupMenuItem(
              padding: const EdgeInsets.only(right: 4),
              child: child,
            );
          },
        ),
      ],
      position: RelativeRect.fromRect(
        _tapPosition! & const Size(40, 40),
        Offset.zero & overlay.semanticBounds.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - (_controller.value * 0.02);
    return GestureDetector(
      onLongPress: _showCustomMenu,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: scale,
        child: widget.child,
      ),
    );
  }
}

class ContextMenuItem {
  ContextMenuItem({
    required this.title,
    required this.onTap,
    required this.icon,
  });
  final String title;
  final Future<void> Function() onTap;
  final dynamic icon;
}
