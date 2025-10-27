import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContextMenu extends StatefulWidget {
  const ContextMenu({
    required this.child,
    required this.items,
    super.key,
  });

  final List<ContextMenuItem> items;
  final Widget child;

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  Offset? _tapPosition;

  Widget _getIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: FaIcon(
        icon,
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

    await showMenu(
      context: context,
      menuPadding: EdgeInsetsGeometry.zero,
      elevation: 1,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // corner radius
      ),
      popUpAnimationStyle: const AnimationStyle(
        duration: Duration.zero,
        curve: Curves.fastOutSlowIn,
      ),
      items: <PopupMenuEntry<int>>[
        ...widget.items.map(
          (item) => PopupMenuItem(
            padding: EdgeInsets.zero,
            child: ListTile(
              title: Text(item.title),
              onTap: () async {
                if (mounted) Navigator.pop(context);
                await item.onTap();
              },
              leading: _getIcon(item.icon),
            ),
          ),
        )
      ],
      position: RelativeRect.fromRect(
        _tapPosition! & const Size(40, 40),
        Offset.zero & overlay.semanticBounds.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showCustomMenu,
      onTapDown: (TapDownDetails details) {
        _tapPosition = details.globalPosition;
      },
      child: widget.child,
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
  final IconData icon;
}
