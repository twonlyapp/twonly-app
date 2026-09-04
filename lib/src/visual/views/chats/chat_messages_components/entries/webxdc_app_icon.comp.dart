import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly.db.dart';

/// One `MemoryImage` per app version, kept for the life of the process.
///
/// `MemoryImage` compares its bytes by identity, so the image cache treats the
/// `Uint8List` a fresh database read hands back as a different image and decodes
/// the same PNG again -- visibly, since the card is already on screen by then.
/// An app version's icon never changes, so holding the provider means every
/// card showing that app resolves out of the image cache instead.
final Map<String, MemoryImage> _providers = {};

/// The app's icon, or the placeholder shown while the store entry is unknown
/// and for an app that published none.
class WebxdcAppIcon extends StatelessWidget {
  const WebxdcAppIcon({
    required this.app,
    required this.size,
    required this.radius,
    required this.color,
    super.key,
  });

  final WebxdcApp? app;
  final double size;
  final double radius;

  /// Both the placeholder's color and, being drawn on a message bubble rather
  /// than on a surface, what the icon has to stay legible against.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final provider = _providerFor(app);
    return SizedBox(
      width: size,
      height: size,
      child: provider == null
          ? FaIcon(
              FontAwesomeIcons.puzzlePiece,
              size: size * 0.6,
              color: color,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image(image: provider, fit: BoxFit.cover),
            ),
    );
  }
}

MemoryImage? _providerFor(WebxdcApp? app) {
  if (app == null) return null;
  final icon = app.icon;
  if (icon == null || icon.isEmpty) return null;
  return _providers.putIfAbsent(
    '${app.appId}:${app.version}',
    () => MemoryImage(icon),
  );
}
